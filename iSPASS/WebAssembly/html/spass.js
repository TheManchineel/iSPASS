let SPASS_CODE = decode(window.programs["SPASS"]) // > 0.7 MiB string lol

const DEFAULT_THEOREM = `begin_problem(Sokrates1).

list_of_descriptions.
name({*Sokrates*}).
author({*Christoph Weidenbach*}).
status(unsatisfiable).
description({* Sokrates is mortal and since all humans are mortal, he is mortal too. *}).
end_of_list.
    
list_of_symbols.
    functions[(sokrates,0)].
    predicates[(Human,1),(Mortal,1)].
end_of_list.
    
list_of_formulae(axioms).
    
formula(Human(sokrates),1).
formula(forall([x],implies(Human(x),Mortal(x))),2).
    
end_of_list.
    
list_of_formulae(conjectures).
    
formula(Mortal(sokrates),3).
    
end_of_list.
    
end_problem.
`

async function runSpass(encodedTheorem, extraArgs = []) {
    let theorem = atob(encodedTheorem);
    console.log(theorem);
    console.log("SPASS is now executing...");
    //    async function runWasi(programBuffer, programArgs = ["program_name.wasm"], programEnv = {}, programStdin = "Hello, World!")
    await runWasi(
        SPASS_CODE,
        ["SPASS", "-Stdin"].concat(extraArgs),
        undefined, // No environment variables
        theorem
    );
//    webkit.messageHandlers.wasiStdoutHandler.postMessage("HI YA :D");
    return {};
}
