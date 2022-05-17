const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
//const tokens = require('./tokens.json');

let whitelistaddress = [
  "0xa111C225A0aFd5aD64221B1bc1D5d817e5D3Ca15",
  "0x8de806462823aD25056eE8104101F9367E208C14",
  "0x801EfbcFfc2Cf572D4C30De9CEE2a0AFeBfa1Ce1",
  "0x7DdC72Eb160F6A325A5927299b2715Abd0bEA55B",
  "0x5aB21736841D90fc48D6aA003A7791E62f52692f",
  "0x940Da56126BE133Ddaa53Fe0FE52B4F42d3f761F",
  "0x7De3e7f2821ef6310B353c00628D02B57ad661D8",
  "0x6B831bf30f30701D5595DedDA9873F9F93495FBb",
  "0x3EE9626735Bc3585D2B4b3B6F604769aB3450593",
  "0xb0874963aCcA3FD8C3740fC13A9948b89D34B19A",
  "0x4Ea6D5DF8291E973289C726b2a36836BF232C0D1",
];

const leaves = whitelistaddress.map((addr) => keccak256(addr));
const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
const root = tree.getRoot().toString("hex");

//check our tree
console.log("Our Merkle tree:\n", tree.toString());
console.log("Merkle tree root:\n", root);

const leaf = keccak256("0xb0874963aCcA3FD8C3740fC13A9948b89D34B19A");
const proof = tree.getProof(leaf);
console.log(tree.verify(proof, leaf, root)); // true
