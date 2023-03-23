import { Button, List, Card, Row, Divider } from "antd";
import React, { useState, useEffect } from "react";
import { Address, AddressInput } from "../components";
import { useContractReader } from "eth-hooks";
import { ethers } from "ethers";

/**
 * web3 props can be passed from '../App.jsx' into your local view component for use
 * @param {*} yourLocalBalance balance on current network
 * @param {*} readContracts contracts from current chain already pre-loaded using ethers contract module. More here https://docs.ethers.io/v5/api/contract/contract/
 * @returns react component
 **/
function Home({
  userSigner,
  readContracts,
  writeContracts,
  tx,
  loadWeb3Modal,
  blockExplorer,
  mainnetProvider,
  address,
}) {
  const [transferToAddresses, setTransferToAddresses] = useState({});

  // 🧠 This effect will update yourCollectibles by polling when your balance changes
  const balanceContract = useContractReader(readContracts, "SolidCircles", "balanceOf", [address]);
  const [balance, setBalance] = useState();
  const [price, setPrice] = useState();

  useEffect(() => {
    if (balanceContract) {
      setBalance(balanceContract);
    }
  }, [balanceContract]);

  const [yourCollectibles, setYourCollectibles] = useState();

  console.log("Home: " + address + ", Balance: " + balance);

  useEffect(() => {
    const updateYourCollectibles = async () => {
      const collectibleUpdate = [];
      for (let tokenIndex = 0; tokenIndex < balance; ++tokenIndex) {
        try {
          console.log("Getting token index " + tokenIndex);
          // 1. gets token id
          const tokenId = await readContracts.SolidCircles.tokenOfOwnerByIndex(address, tokenIndex);
          console.log("tokenId: " + tokenId);
          // 2. gets token uri
          const tokenURI = await readContracts.SolidCircles.tokenURI(tokenId);
          const jsonManifestString = Buffer.from(tokenURI.substring(29), "base64").toString();
          console.log("jsonManifestString: " + jsonManifestString);

          try {
            // 3. parses the token uri
            const jsonManifest = JSON.parse(jsonManifestString);
            console.log("jsonManifest: " + jsonManifest);
            // 4. adds the token id, uri, and owner to the collectible collectibleUpdate array
            collectibleUpdate.push({ id: tokenId, uri: tokenURI, owner: address, ...jsonManifest });
          } catch (err) {
            console.log(err);
          }
        } catch (err) {
          console.log(err);
        }
      }
      // sets local state with the collectibleUpdate reverse array
      setYourCollectibles(collectibleUpdate.reverse());
      setPrice(await readContracts.SolidCircles.PRICE());
    };
    if (address && balance) updateYourCollectibles();
  }, [address, balance]);

  return (
    <div>
      <div style={{ maxWidth: 820, margin: "auto", marginTop: 32, paddingBottom: 32 }}>
        {userSigner ? (
          <div>
            {" "}
            <h1 style={{ marginBottom: "10px" }}> 🔮SolidCircles </h1>{" "}
            <div>
              Limited edition artwork (only 777) created by blending different color layers, which interact with one
              another and gradually move at varying velocities, resulting in an NFT that continuously transforms and
              shifts in color.
            </div>
            {price && (
              <div style={{ flexDirection: "", fontSize: "0.75rem", paddingTop: "15px", marginBottom: "" }}>
                Current Mint Price: {ethers.utils.formatEther(price)}
                <b>&nbsp;ETH </b>
              </div>
            )}
            <Divider />
            <Button
              type={"primary"}
              onClick={() => {
                tx(
                  writeContracts.SolidCircles.mintItem({
                    value: price,
                  }),
                );
                console.log("MINTED");
              }}
            >
              MINT
            </Button>
          </div>
        ) : (
          <Button type={"primary"} onClick={loadWeb3Modal}>
            CONNECT WALLET
          </Button>
        )}
      </div>

      <div style={{ width: 820, margin: "auto", paddingBottom: 256 }}>
        <List
          bordered
          dataSource={yourCollectibles}
          renderItem={item => {
            console.log("ITEM", item);
            const id = item.id.toNumber();

            console.log("IMAGE", item.image);

            return (
              <List.Item key={id + "_" + item.uri + "_" + item.owner}>
                <Card
                  title={
                    <div>
                      <span style={{ fontSize: 18, marginRight: 8 }}>{item.name}</span>
                    </div>
                  }
                >
                  <a
                    href={
                      "https://mainnet.opensea.io/assets/optimism/" +
                      (readContracts && readContracts.SolidCircles && readContracts.SolidCircles.address) +
                      "/" +
                      item.id
                    }
                    target="_blank"
                    rel="noreferrer"
                  >
                    <img src={item.image} />
                  </a>
                  <div>{item.description}</div>
                </Card>

                <div>
                  owner:{" "}
                  <Address
                    address={item.owner}
                    ensProvider={mainnetProvider}
                    blockExplorer={blockExplorer}
                    fontSize={16}
                  />
                  <AddressInput
                    ensProvider={mainnetProvider}
                    placeholder="transfer to address"
                    value={transferToAddresses[id]}
                    onChange={newValue => {
                      const update = {};
                      update[id] = newValue;
                      setTransferToAddresses({ ...transferToAddresses, ...update });
                    }}
                  />
                  <Button
                    onClick={() => {
                      console.log("writeContracts", writeContracts);
                      tx(writeContracts.SolidCircles.transferFrom(address, transferToAddresses[id], id));
                    }}
                  >
                    Transfer
                  </Button>
                </div>
              </List.Item>
            );
          }}
        />
      </div>
    </div>
  );
}

export default Home;
