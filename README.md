# <p align="center"> HORIZON

</p>

<p align="center"> Chainlink Constellation Hackathon
</p>
</br>

1. Introduction
   - What is _consórcio_?
   - Why is it relevant?
   - How does _consórcio_ works
2. About the protocol
3. How does it works
   </br>

---

</br>

## 1. Introduction

We, humans, have one thing in common: we have dreams! We dream of owning a house, buying a new car, pursuing a degree or specialization to boost our professional career, and we dream of the warm, crystal-clear waters of the Caribbean. But, we wake up to reality when we open our online account and check our balance.
How many dreams have you failed to realize due to lack of money?
To overcome this, Brazilians have created the _consórcio_!

</br>

### What is _consórcio_?

The _consórcio_, created in 1962 due to the lack of availability of credit lines, is a tool for collective self-financing through which people come together to acquire something they desire, such as a car, a property, or even services. It is managed by an administrative entity, which, in the case of Brazil, is regulated and supervised by the government. This tool has become popular and has even been adopted by other countries such as Argentina, Uruguay, Paraguay, Peru, Mexico, and Venezuela (Source: [ABAC - History](https://abac.org.br/o-consorcio/historia)).

</br>

### Why is it relevant?
The wide adoption of the _consórcio_ system, which grows year after year, is attributed, among other factors, mainly to the power of inclusion and financial discipline that this tool promotes. Beyond that, this is a product in full expansion in the traditional system and little explored, which, in web3, has even greater potential given that we can reach other countries. Let's look at some data about the _consórcio_ in Brazil (Source: [ABAC - September details Press Release](https://abac.org.br/imprensa/press-releases-detalhe&id=383)).

</br>

From January to September 2023:
- More than 3 million new quotas were sold
- That is, an average of 350 thousand sales per month
- This represents an increase of 6.8% compared to the same period last year
- There are almost 10 million active participants, which is about 5.4% of Brazil's population
- Whose average ticket is 15 thousand dollars
- There was also an increase of 28.9% in contemplations (that means, drawn quotas)
- Which directly injected more than 12 billion dollars into the economy
- And moved more than 50 billion dollars in traded credits
- In 2022, this represented a participation of 4.7% in the GDP, contributing to the country's development

</br>

If we project these values globally, considering only countries similar to Brazil (in terms of per capita income, see details of this study [here](https://docs.google.com/spreadsheets/d/1L7-VuZEdYFtonFrzvHYbFk2gRbB-TP_TIUpr_jgzv-Q/edit?usp=sharing)), we would have:

- 57 countries with the potential for adoption
- That adds up to more than 520 million people
- Which could represent more than 28 million customers (considering the same 5.4% of the Brazilian population that already joined the _consórcio_)
- Representing an injection of more than 33 billion dollars into the economy
- And a movement of 140 billion dollars in traded credits over one year

<br/>

### How does _consórcio_ works

</br>

## 2. About the protocol

Horizon is a DEFI protocol aimed at simplifying access to the Web3 ecosystem, primarily for people with middle to low-income, making the process safer, more transparent, and auditable. With the imminent advancement of Tokenized Assets, we go further by implementing a logic that allows these Assets to be used as collateral for withdrawing the value of the acquired _Consórcio_ Title. To make this possible and to enable its use in various regions of the planet, in addition to the reliability of the Chainlink tools that will be used, the main barrier that needs to be overcome is the onboarding process, which until recently was restrictive due to the limited options of available Wallets. Today, we have a great ally in ERC-4337. And this is the first step towards changing the lives of many people
</br>

### Would you like to learn more about Tokenized Assets and ERC-4337? Access the links below:
Real World Assets [RWA](https://www.coindesk.com/learn/rwa-tokenization-what-does-it-mean-to-tokenize-real-world-assets/) </br>
Account Abstraction [ERC-4337](https://www.erc4337.io)

# How does it works

---

# Application in the Constellation Hackathon
Our [pitch](https://youtu.be/LdYLifCuKFo).
You can access [Horizon](https://horizon-dapp.vercel.app) live demo. </br>

## This prototype will simulate the following stages:

- [X] Creation of Consórcio Titles;
- [X] Commercialization of Consórcio Quotas;
- [X] Conducting Consórcio Quota Lottery via VRF;
- [X] Payments, Delays, and Application of Interest;
- [X] Creation of Allocation Permissions through Chainlink CCIP;
- [X] Verification of Guarantees;
- [X] Allocation of Guarantees and Chainlink Automated Monitoring of Value following FIPE through Chainlink Functions.

## Tools Used

- ### Chainlink VRF - Verifiable Random Function
  Chainlink VRF is a crucial part of the protocol's operability, as the trust, transparency, and security provided by the tool are essential for all other functionalities to be performed correctly. The verifiable randomness, cryptographic security, decentralization, and integration with Smart Contracts make the results presented by the tool unquestionable.

- ### Chainlink CCIP - Cross-Chain Interoperability Protocol
  Chainlink CCIP allows Horizon to offer inclusion to diverse peoples and cultures by enabling communication between various blockchains and allowing the integration and use of assets from different parts of the globe in a secure and decentralized manner. Specifically, Horizon, will enable the creation of allocation permissions for guarantees on all Ethereum-compatible networks and, in the future, may integrate the protocol with specific networks of each country.

- ### Chainlink Functions
  Chainlink Functions will carry out the collection of necessary data for the allocation of Assets according to their respective off-chain databases. Furthermore, it could assist in the future with the implementation of liquidation measures or alerts to the respective owners of the assets allocated in the protocol.
  It is responsible for collecting data through the FIPE API, bringing on-chain data of automobiles that will be used as examples of tokenized assets for guarantees.

- ### Chainlink Automation - Chainlink’s hyper-reliable Automation network
  Chainlink Automation is essential for the maintenance of the protocol. It will be responsible, along with Chainlink Functions, for the periodic collection of updated data from the allocated guarantees. This involves requesting the data and storing it based on the emitted response log. Thus, the protocol has mechanisms that ensure the health of the ecosystem.
  Moreover, it could be used to conduct draws and automate processes for a possible new protocol stage.

- ### API - Application Programming Interface
  Responsible for collecting information from the database of [FIPE](https://www.fipe.org.br) - Fundação Instituto de Pesquisas Econômicas (Foundation for Economic Research Institute).

## Operation

The protocol is developed using smart contracts in Solidity. These contracts enable the Protocol Administration to create _Consórcio_ Titles of various values and durations. These Consórcios have a limited number of participants and each Consórcio has an interest policy against delinquency. This is defined before their creation.

## Commercialization of _Consórcio_ Titles

Upon acquiring a _Consórcio_ Quota, the client has two main options for withdrawal:

- Immediate Withdrawal
  Allows the client to withdraw the amount immediately after being drawn.
  Administration Fee: 10% of the Quota value, diluted monthly.

- Conditional Withdrawal
  Withdrawal is only permitted after the Title exceeds the mark of 50% of the participants drawn.
  Administration Fee: 5% of the Quota value, diluted in monthly installments.

For example, if the total number of draws is 10, withdrawal can only be made from draw 6 onwards, even if the client has been drawn earlier.

## Investment of Received Funds

The funds received from Conditional Withdrawal titles will be invested in partner protocols to generate additional revenue for Horizon.
Objective: This process aims to enhance the financial sustainability of the protocol and offer better opportunities to participants.

## Withdrawal Conditions

The withdrawal of a drawn consórcio quota is not unrestricted. Withdrawal is conditional upon meeting one of the following conditions:

Full Payment of the Consórcio quota: The total value of the quota must be paid.
Allocation of Guarantees: The client may choose to allocate guarantees to enable the withdrawal.

- Allocation of Guarantees
  The client has two main options for guarantee allocation:

- Use of Paid-Up or Partially Paid _Consórcio_ Quotas
  Quotas that have been fully paid up or with an amount paid more than twice the outstanding value of the quota in which the guarantee will be allocated.
  Applicability: This option is ideal for clients who possess other titles with significant payments already made.
- Use of Tokenized Assets
  Tokenized Assets can be used as collateral for withdrawal.
  Advantage: Provides a flexible alternative for clients who own tokenized digital assets.

## Allocation of Collaterals

After a Quota is drawn, the winner has the option to allocate guarantees to release the value. This allocation can be done in two main ways: using other titles or utilizing Tokenized Assets.

### Allocation Process Using Titles
To use a title as collateral, the owner of the drawn title needs to provide some essential information:

Identifier of the Drawn _Consórcio_ Title: Identification number of the title that your quota was drawn.
Identifier of Your Drawn Quota: Number of your quota or participation in the drawn title.
Identifier of the _Consórcio_ Title Used as Collateral: Identification number of the title that the quota you wish to use as collateral.
Identifier of Your Quota in the Collateral Title: Number of your quota that will be used as collateral.

#### Practical Example:
* Drawn _Consórcio_ Title: 10
   * Your Quota in the Drawn _Consórcio_ Title: 30
* _Consórcio_ Title for Collateral: 5
   * Your Quota in the Collateral Title: 15

If the value of quota 15 from _Consórcio_ 5, used as collateral, meets the requirements, it will be transferred to the protocol, allocated as the guarantee for quota 30 of _Consórcio_ 10, and the prize amount will be released.

### Allocation Using Tokenized Assets
Tokenized Assets are digital assets that represent ownership of a real or virtual property. They can be used as collateral in the following ways:

**Network Compatibility:** The Tokenized Asset can be allocated on any network compatible with the CCIP that Horizon operates. <br/>
**Value Assessment:** Before allocation, the value of the Tokenized Asset is assessed through Chainlink Functions and the FIPE API. If it is equivalent to or greater than the minimum value required for the _Consórcio_ quota, it will be accepted as collateral. <br/>
**Automated Monitoring:** After allocation, the value of the Tokenized Asset is automatically monitored. If there are significant variations in value, measures can be taken to maintain the integrity of the protocol.

## _Consórcio_ Quota Withdrawl
The withdrawal of the Quota value is an important process in the Horizon protocol and can be performed under two main conditions:

**Full Payment of the Title:** Withdrawal is permitted after the full payment of the Quota value. <br/>
**Allocation of Guarantees:** If guarantees are allocated according to the protocol's rules, withdrawal is also released. <br/>

### Withdrawal Process
Once one of the above conditions is met, the withdrawal process can be initiated:

**Owner's Initiative:** Typically, the quota owner initiates the withdrawal. <br/>
**Administrative Intervention:** In specific cases, the protocol administration can transfer the withdrawal value directly to the quota owner. This may occur for operational or exceptional reasons defined by the protocol. <br/>

### Flexibility and Security
This withdrawal system has been designed to offer flexibility to users while maintaining the security and integrity of the protocol.

## Management of Delinquency and Interest

### Payment Policy
**Payment Dates:** The payment dates for each _Consórcio_ Title are established at the time of their creation. <br/>
**Administrative Flexibility:** The protocol administration has the prerogative to postpone payment dates if necessary, but never to advance them.

### Delinquency and Interest Application
**Attention to Dates:** Clients must be attentive to payment dates to avoid delinquency. <br/>
**Interest for Late Payment:** In case of payment delay, the pre-defined interest will be applied. These interest rates are established at the creation of the _Consórcio_ Title and aim to maintain the financial health of the protocol. <br/>
**Consequences of Delinquency:** If the payment delay exceeds two installments, the _Consórcio_ quota will be considered delinquent and subject to cancellation.

## _Consórcio_ Quota Cancellation
**Cancellation Process:** The cancellation of a Quota is a last resource measure, applied only in cases of significant delinquency.
**Impact of Cancellation:** The cancellation of a quota can have financial implications for the holder, including the loss of any payments already made.

## Penalty Policy

### Purpose of Penalties
**Function of Penalties:** Penalties are applied in the event of a quota cancellation to ensure the stability of the protocol and to protect the interests of the other participants.

### Penalties on Quotas without Allocated Guarantees
**Pre-Draw Cancellation:** If a quota is canceled before being drawn and does not have allocated guarantees, the amount already paid by the holder will be retained as a penalty. <br/>
**Purpose:** This measure aims to offset the financial impact of the cancellation on the overall fund pool.

### Penalties on Quotas with Allocated Guarantees
**Post-Draw Cancellation with Guarantee:** For Quotas canceled after the draw, in which guarantees have already been allocated, the guarantee will be forfeited as a penalty.
**Treatment of the Guarantee:** The confiscated guarantee will be sold in the secondary market. The proceeds will be used to cover the penalty corresponding to the canceled quota.

## Return of the Guarantee

After the settlement of all installments, the allocated guarantee is returned to the same address responsible for the allocation in the Quota.

# Evolution of the Protocol

Given the structure presented, the protocol has vast potential for growth and evolution. Among the points that have been discussed, we have:

1 - **Optimization of Phase 1**.
Given the billion-dollar market for investments of this nature, we need to reinforce our structure. This involves restructuring smart contracts for real environments, conducting audits, and redesigning UI and UX. Additionally, economic studies and local market analyses are crucial to gauge the challenges of expansion. <br/>

Measures such as developing classifications for accepted guarantees can reduce the final costs of the _Consórcio_. Therefore, cost management, adjustments of fees and penalties, processing of guarantees, more comprehensive studies, and targeted research can create new strategic advantages, always aiming for a better experience and greater opportunities for the end user. It is important to emphasize that beyond internal focus, we are aware that to expand our target audience we will also face legal challenges. 

2 - **Creation of a Secondary Market for the Commercialization of _Consórcio_ Quotas**
With the creation of the Secondary Market, quota holders will have the freedom to trade them. This could involve reducing the quota price for a quick sale in case of need or even marking up the sale of a quota that has been drawn. From this, the protocol benefits from increased liquidity, as the market will be able to dynamically price the Quotas based on supply and demand, making the process fairer and more transparent. </br>

Moreover, it opens a door for clients to diversify their investment portfolio, reduces delinquency, facilitates access for new participants, and stimulates participation since, despite having committed, a participant can transfer their Quota if necessary. </br>

Finally, the introduction of a secondary market can lead to additional innovations and the growth of the Horizon ecosystem, attracting more users and investors and enhancing the robustness and resilience of the system. </br>

3 - **Encouragement of Partnerships for the Creation of New Pools for Yield on Locked Values**
Developing new partnerships can bring numerous strategic and operational benefits, expanding the reach of the Protocol. Among these, we have: 

- Access to new markets through other DeFi protocols or traditional finance significantly increases the number of users;
- Expansion of Resources and Diversification of Investments, tailoring to regional supply and demand;
- Long-term sustainability by providing stability and continuous innovation.

4 - **Loan Services Using Tokenized Assets as Collateral**

- Expands Horizon's scope to countries with lower interest rates where, initially, _consórcio_ would not be a viable option;
- Facilitates access to short-term liquidity using Tokenized Assets;
- Lower interest rates due to the allocated collateral;
- Efficiency in the process;
- Generates liquidity for the Tokenized Asset market;
- Growth of the protocol as more assets are tokenized around the world.

Chainlink Data Streams would be a crucial tool for the proper functioning of the protocol, as well as for monitoring Tokenized Assets.

5 - **Financing Using Tokenized Assets as Collateral**

- Easy and quick access to capital, especially for entrepreneurs;
- Access to financing for large purchases such as real estate, furniture, and general equipment.
- Due to the guaranteed nature, we can offer favorable financing conditions such as lower interest rates and flexible repayment terms according to the need.

 </br>
 
All the potential scenarios presented converge to efficient and transparent processes through the employed technology and generate financial inclusion for individuals and businesses that lack access to loans from traditional institutions but have assets and need to create value from them.

 </br>

In summary, the initial product and its possible developments are not only useful for investors but also for people who, in times of need, can meet specific demands such as health issues by acquiring loans and financing quickly and conveniently using their assets as collateral.

# Conclusion

Horizon represents a significant advancement in democratizing access to the Web3 ecosystem, with a special focus on the financial inclusion of middle and low-income individuals. By integrating innovative technologies such as Chainlink VRF, CCIP, Functions, and Automation, and the integration with the FIPE Table, Horizon establishes a new standard in terms of security, transparency, and auditability in decentralized financial operations. <br/>

Through the implementation of a robust _consórcio_ system, Horizon not only facilitates the acquisition of goods and services but also paves the way for the efficient use of Tokenized Assets as collateral, expanding the possibilities for withdrawal and investment for users. This aspect is particularly revolutionary as it leverages the potential of digital assets in a way that directly benefits the end-user while maintaining the integrity and sustainability of the system. <br/>

Furthermore, Horizon's structure is designed to evolve and adapt to the emerging needs of the market and users. With plans that include the creation of a secondary market for titles, exploring partnerships for additional yields, and expanding into loan and financing services, Horizon is not just a solution for the present but an investment in the future of decentralized finance. <br/>

# Developer Session

## Smart contracts
[Horizon](contracts/Horizon.sol) <br/>
[HorizonS](contracts/HorizonS.sol) <br/>
[HorizonStaff](contracts/HorizonStaff.sol) <br/>
[HorizonVRF](contracts/HorizonVRF.sol) <br/>
[HorizonFujiR](contracts/HorizonFujiR.sol) <br/>
[HorizonFujiS](contracts/HorizonFujiS.sol) <br/>
[HorizonFunctions](contracts/HorizonFunctions.sol) <br/>
[HorizonFujiAssistant](contracts/HorizonFujiAssistant.sol) <br/>
[FakeRWA](contracts/FakeRWA.sol) <br/>

## Blockchains
[Polygon](https://polygon.technology) <br/>
[Avalanche](https://www.avax.network) <br/>

## Tools
[Chainlink Automation](https://docs.chain.link/chainlink-automation) <br/>
[Chainlink CCIP](https://docs.chain.link/ccip) <br/>
[Chainlink Functions](https://docs.chain.link/chainlink-functions) <br/>
[Chainlink VRF](https://docs.chain.link/vrf) <br/>

## API
- [API GitHub Repository](https://github.com/deividfortuna/fipe)  <br/>
- API_Key: https://parallelum.com.br/fipe/api/v1/${tipoAutomovel}/marcas/${idMarca}/modelos/${idModelo}/anos/${dataModelo}  <br/>
- Input used in demo - ["motos","77","5223","2015-1"].  <br/>

## Want to try Thunder Client?

- **Body**
  {
  "codigoTipoVeiculo": motos,
  "idMarca": 77,
  "idModelo": 5223,
  "dataModelo": "2015-1",
  }

- **Response**
  {
  "TipoVeiculo": 2,
  "Valor": "R$ 41.761,00",
  "Marca": "HARLEY-DAVIDSON",
  "Modelo": "XL 883N IRON",
  "AnoModelo": 2015,
  "Combustivel": "Gasolina",
  "CodigoFipe": "810052-7",
  "MesReferencia": "novembro de 2023",
  "SiglaCombustivel": "G"
  }
