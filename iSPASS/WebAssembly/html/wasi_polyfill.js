const textEncoder = new TextEncoder();

class Wasi {
    #encodedStdin;
    #envEncodedStrings;
    #argEncodedStrings;
    #instance;

    constructor({ env, stdin, args }) {
        this.#encodedStdin = textEncoder.encode(stdin);
        const envStrings = Object.entries(env).map(([k, v]) => `${k}=${v}`);
        this.#envEncodedStrings = envStrings.map(s => textEncoder.encode(s + "\0"))
        this.#argEncodedStrings = args.map(s => textEncoder.encode(s + "\0"));
        this.bind();
    }

    //really annoying the interface works this way but we MUST set the instance after creating it with the WASI class as an import in order to access its memory
    set instance(val) {
        this.#instance = val;
    }

    /// STUBBED FUNCTIONS (TBI) //////////////////////////

    fd_close() { console.log("fd_close"); return 0; }
    fd_fdstat_get() { console.log("fd_fdstat_get"); return 0; }
    fd_fdstat_set_flags() { console.log("fd_fdstat_set_flags"); return 0; }
    fd_prestat_get() { console.log("fd_prestat_get"); return 0; }
    fd_prestat_dir_name() { console.log("fd_prestat_dir_name"); return 0; }
    fd_seek() { console.log("fd_seek"); return 0; }
    path_open() { console.log("path_open"); return 0; }
    path_remove_directory() { console.log("path_remove_directory"); return 0; }
    path_unlink_file() { console.log("path_unlink_file"); return 0; }

    /////////////////////////////////////////////////////

    // Doesn't seem to do anything with SPASS yet, time always appears as 00:00:00
    clock_time_get() { return 1000 * Date.now(); }

    bind() {
        this.args_get = this.args_get.bind(this);
        this.args_sizes_get = this.args_sizes_get.bind(this);
        this.environ_get = this.environ_get.bind(this);
        this.environ_sizes_get = this.environ_sizes_get.bind(this);
        this.fd_read = this.fd_read.bind(this);
        this.fd_write = this.fd_write.bind(this);
    }

    args_sizes_get(argCountPtr, argBufferSizePtr) {
        const argByteLength = this.#argEncodedStrings.reduce((sum, val) => sum + val.byteLength, 0);
        const countPointerBuffer = new Uint32Array(this.#instance.exports.memory.buffer, argCountPtr, 1);
        const sizePointerBuffer = new Uint32Array(this.#instance.exports.memory.buffer, argBufferSizePtr, 1);
        countPointerBuffer[0] = this.#argEncodedStrings.length;
        sizePointerBuffer[0] = argByteLength;
        return 0;
    }
    args_get(argsPtr, argBufferPtr) {
        const argsByteLength = this.#argEncodedStrings.reduce((sum, val) => sum + val.byteLength, 0);
        const argsPointerBuffer = new Uint32Array(this.#instance.exports.memory.buffer, argsPtr, this.#argEncodedStrings.length);
        const argsBuffer = new Uint8Array(this.#instance.exports.memory.buffer, argBufferPtr, argsByteLength)


        let pointerOffset = 0;
        for (let i = 0; i < this.#argEncodedStrings.length; i++) {
            const currentPointer = argBufferPtr + pointerOffset;
            argsPointerBuffer[i] = currentPointer;
            argsBuffer.set(this.#argEncodedStrings[i], pointerOffset)
            pointerOffset += this.#argEncodedStrings[i].byteLength;
        }

        return 0;
    }
    fd_write(fd, iovsPtr, iovsLength, bytesWrittenPtr) {
        const iovs = new Uint32Array(this.#instance.exports.memory.buffer, iovsPtr, iovsLength * 2);
        if (fd === 1) { //stdout
            let text = "";
            let totalBytesWritten = 0;

            const decoder = new TextDecoder();
            for (let i = 0; i < iovsLength * 2; i += 2) {
                const offset = iovs[i];
                const length = iovs[i + 1];
                const textChunk = decoder.decode(new Int8Array(this.#instance.exports.memory.buffer, offset, length));
                text += textChunk;
                totalBytesWritten += length;
            }

            const dataView = new DataView(this.#instance.exports.memory.buffer);
            dataView.setInt32(bytesWrittenPtr, totalBytesWritten, true);
            webkit.messageHandlers.wasiStdoutHandler.postMessage(text)
            console.log(text)
            // document.querySelector(".stdout").innerHTML += text.replace(/\n/g, "<br>");
        }
        return 0;
    }
    fd_read(fd, iovsPtr, iovsLength, bytesReadPtr) {
        const memory = new Uint8Array(this.#instance.exports.memory.buffer);
        const iovs = new Uint32Array(this.#instance.exports.memory.buffer, iovsPtr, iovsLength * 2);
        let totalBytesRead = 0;
        if (fd === 0) {//stdin
            for (let i = 0; i < iovsLength * 2; i += 2) {
                const offset = iovs[i];
                const length = iovs[i + 1];
                const chunk = this.#encodedStdin.slice(0, length);
                this.#encodedStdin = this.#encodedStdin.slice(length);

                memory.set(chunk, offset);
                totalBytesRead += chunk.byteLength;

                if (this.#encodedStdin.length === 0) break;
            }

            const dataView = new DataView(this.#instance.exports.memory.buffer);
            dataView.setInt32(bytesReadPtr, totalBytesRead, true);
        }
        return 0;
    }
    environ_get(environPtr, environBufferPtr) {
        const envByteLength = this.#envEncodedStrings.map(s => s.byteLength).reduce((sum, val) => sum + val, 0);
        const environsPointerBuffer = new Uint32Array(this.#instance.exports.memory.buffer, environPtr, this.#envEncodedStrings.length);
        const environsBuffer = new Uint8Array(this.#instance.exports.memory.buffer, environBufferPtr, envByteLength)

        let pointerOffset = 0;
        for (let i = 0; i < this.#envEncodedStrings.length; i++) {
            const currentPointer = environBufferPtr + pointerOffset;
            environsPointerBuffer[i] = currentPointer;
            environsBuffer.set(this.#envEncodedStrings[i], pointerOffset)
            pointerOffset += this.#envEncodedStrings[i].byteLength;
        }

        return 0;
    }
    environ_sizes_get(environCountPtr, environBufferSizePtr) {
        const envByteLength = this.#envEncodedStrings.map(s => s.byteLength).reduce((sum, val) => sum + val, 0);
        const countPointerBuffer = new Uint32Array(this.#instance.exports.memory.buffer, environCountPtr, 1);
        const sizePointerBuffer = new Uint32Array(this.#instance.exports.memory.buffer, environBufferSizePtr, 1);
        countPointerBuffer[0] = this.#envEncodedStrings.length;
        sizePointerBuffer[0] = envByteLength;
        return 0;
    }
    proc_exit() {
        console.log("Process completed");
    }
}

//function asciiToBinary(str) {
//    if (typeof atob === 'function') {
//        // this works in the browser
//        return atob(str)
//    } else {
//        // this works in node
//        return new Buffer(str, 'base64').toString('binary');
//    }
//}

function decode(encoded) {
//    var binaryString = asciiToBinary(encoded);
    var binaryString = atob(encoded);
    var bytes = new Uint8Array(binaryString.length);
    for (var i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes.buffer;
}

async function runWasi(programBuffer, programArgs = ["program_name.wasm"], programEnv = {}, programStdin = "Hello, World!") {
    console.log("Preparing WASI runner...")
    try {
        let wasi = new Wasi({
        stdin: programStdin,
        env: programEnv,
        args: programArgs
        });
        console.log("About to instantiate WASM module");
        const { instance } = await WebAssembly.instantiate(programBuffer, {
            "wasi_snapshot_preview1": wasi
        }); // WebAssembly.module
        wasi.instance = instance;
        console.log("About to start entrypoint...");
        instance.exports._start();
    } catch (e) {
        console.log(`EXCEPTION: ${e}`);
    }
}
