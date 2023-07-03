This repository contains my own implementation of the solutions for the ZKP-MOOC-Lab 2023 project. All solutions within this fork are crafted, ensuring soundness and optimization for the majority.

I welcome fellow coders, learners, and enthusiasts to utilize this repository as a reference for their learning journey. Moreover, fostering a community-driven learning process is at the heart of this initiative. So, let's engage in discussions and send pull request for more efficient solutions.


## My implementation on Task 2: Generate a zk-SNARK proof using snarkjs
> The first 9 steps are skipped by leveraging existed `powersOfTau28_hez_final_08.ptau` file. I followed the step in `snarkjs` [README](https://github.com/iden3/snarkjs)

### 10. Compile the circuit

```bash
circom circuits/example.circom --r1cs --wasm --sym
```

### 11. **View information about the circuit**

```bash
snarkjs r1cs info example.r1cs
```

### 12. Print the circuit

```bash
snarkjs r1cs print example.r1cs example.sym
```

### 13. **Export r1cs to json**

```bash
snarkjs r1cs export json example.r1cs example.r1cs.json
cat example.r1cs.json
```

### 14. **Calculate the witness**

```bash
cd example_js
node generate_witness.js example.wasm ../input.json ../witness.wtns
```

```json
// input.json

{"product":2261, "factors": [7, 17, 19]}
```

### 15. Setup using Groth16

```bash
snarkjs groth16 setup example.r1cs powersOfTau28_hez_final_08.ptau circuit_0000.zkey
```

### 16. **Contribute to the phase 2 ceremony**

```bash
snarkjs zkey contribute circuit_0000.zkey circuit_0001.zkey --name="1st Contributor Name" -v
```

### 17. **Provide a second contribution**

```bash
snarkjs zkey contribute circuit_0001.zkey circuit_0002.zkey --name="Second contribution Name" -v
```


### 18. **Provide a third contribution using third party software**

```bash
snarkjs zkey export bellman circuit_0002.zkey challenge_phase2_0003
snarkjs zkey bellman contribute bn128 challenge_phase2_0003 response_phase2_0003 -e="zkpmooc"
snarkjs zkey import bellman circuit_0002.zkey response_phase2_0003 circuit_0003.zkey -n="Third contribution name"
```

### 19. **Verify the latest `zkey`**

```bash
snarkjs zkey verify example.r1cs powersOfTau28_hez_final_08.ptau circuit_0003.zkey
```

### 20. **Apply a random beacon & Generate the final `zkey`**

```bash
snarkjs zkey beacon circuit_0003.zkey circuit_final.zkey 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon phase2"
```


### 21. **Verify the final `zkey`**

```bash
snarkjs zkey verify example.r1cs powersOfTau28_hez_final_08.ptau circuit_final.zkey
```


### 22. **Export the verification key**

```bash
snarkjs zkey export verificationkey circuit_final.zkey verification_key.json
```


### 23. Create the proof using Groth16

```bash
snarkjs groth16 prove circuit_final.zkey witness.wtns proof.json public.json
```


### 24. Verify the proof

```bash
snarkjs groth16 verify verification_key.json public.json proof.json
```

### [Additional] Convert Verifier into a smart contract

> Leveraging ZKP on blockchain ecosystem

```bash
# export the verifier as a Solidity smart-contract
snarkjs zkey export solidityverifier circuit_final.zkey verifier.sol

# use soliditycalldata to simulate a verification call
snarkjs zkey export soliditycalldata public.json proof.json
```