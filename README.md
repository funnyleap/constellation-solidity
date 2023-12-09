# <p align="center"> HORIZON

</p>

<p align="center"> Chainlink Constellation Hackathon
</p>
</br>

1. [Introduction](https://github.com/BellumGalaxy/constellation-bg#1-introduction)

   1.1. What is _consórcio_?

   1.2. Why is it relevant?

   1.3. How does _consórcio_ works?
   
   1.4. _Consórcio_ Advantages
   
2. [Horizon Protocol](https://github.com/BellumGalaxy/constellation-bg#2-horizon-protocol)

   2.1. The Prototype
   
3. [Tools Used](https://github.com/BellumGalaxy/constellation-bg#3-tools-used)

   3.1. Chainlink VRF - Verifiable Random Function

   3.2. Chainlink CCIP - Cross-Chain Interoperability Protocol

   3.3. Chainlink Functions

   3.4. Chainlink Automation - Chainlink’s hyper-reliable Automation network

   3.5. [Chainlink Tools Summary Table](https://github.com/BellumGalaxy/constellation-bg#35-chainlink-tools-summary-table)

   3.6. API - Application Programming Interface

4. [Operation](https://github.com/BellumGalaxy/constellation-bg#4-operation)

   4.1. Commercialization of _Consórcio_ Titles

   4.2. Investment of Received Funds

   4.3. Withdrawal Conditions

   4.4. Allocation of Collaterals

   4.4.1. Allocation Process Using Titles

   4.4.2. Allocation Using Tokenized Assets

   4.5. _Consórcio_ Quota Withdrawal

   4.5.1. Withdrawal Process

   4.5.2. Flexibility and Security

   4.6. Management of Default and Interest

   4.6.1. Payment Policy

   4.6.2. Default and Interest Application

   4.7. _Consórcio_ Quota Cancellation

   4.8. Penalty Policy

   4.8.1. Purpose of Penalties

   4.8.2. Penalties on Quotas without Allocated Guarantees

   4.8.3. Penalties on Quotas with Allocated Guarantees

   4.8.4. Return of the Guarantee

5. [_Consórcio_ Cost Projection](https://github.com/BellumGalaxy/constellation-bg?tab=readme-ov-file#5-cons%C3%B3rcio-cost-projection)

   5.1. Objective

   5.2. _Consórcio_ Title - Matic

   5.3. Chainlink Tools - Link

   5.4. Total Cost - $

   5.5. _Consórcio_ Title - Withdraw Modalities

   5.6. Average Ticket Practiced in Brazil

   5.7. Monthly income

   5.8. Conclusion

   5.9. Research References

6. [Evolution of the Protocol](https://github.com/BellumGalaxy/constellation-bg?tab=readme-ov-file#6-evolution-of-the-protocol)

   6.1. Optimization of Phase 1

   6.2. Creation of a Secondary Market for the Commercialization of _Consórcio_ Quotas

   6.3. Encouragement of Partnerships for the Creation of New Pools for Yield on Locked Values

   6.4. Loan Services Using Tokenized Assets as Collateral

   6.5. Financing Using Tokenized Assets as Collateral

7. [Conclusion](https://github.com/BellumGalaxy/constellation-bg?tab=readme-ov-file#7-conclusion)
   
8. [Developer Session](https://github.com/BellumGalaxy/constellation-bg?tab=readme-ov-file#8-developer-session)

   8.1. Smart contracts

   8.2. Blockchains

   8.3. Tools

   8.4. API

   8.5. Want to try Thunder Client?
    
</br>

### Horizon Links

- Pitch deck presentation is available on [YouTube](https://www.youtube.com/watch?v=fGnu5_pe2V4)
- Live demo [website](https://horizon-dapp.vercel.app)

</br>

---

</br>

## 1. Introduction

We, humans, have one thing in common: we have dreams! We dream of owning a house, buying a new car, pursuing a degree or specialization to boost our professional career, and we dream of the warm, crystal-clear waters of the Caribbean. But, we wake up to reality when we open our online account and check our balance.
How many dreams have you failed to realize due to lack of money?
To overcome this, Brazilians have created the _consórcio_!

</br>

### 1.1. What is _consórcio_?

The _consórcio_, created in 1962 due to the lack of availability of credit lines, is a tool for collective self-financing through which people come together to acquire something they desire, such as a car, a property, or even services. It is managed by an administrative entity, which, in the case of Brazil, is regulated and supervised by the government. This tool has become popular and has even been adopted by other countries such as Argentina, Uruguay, Paraguay, Peru, Mexico, and Venezuela (Source: [ABAC - History](https://abac.org.br/o-consorcio/historia)).

</br>

### 1.2. Why is it relevant?

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

### 1.3. How does _consórcio_ works?

In a _consórcio_, the value of the good or service is diluted over a predetermined period, and all group members contribute throughout this period. Monthly (or as stipulated in the contract), the administrator contemplates them, either by draw or bid, with the credit in the amount of the contracted good or service, until all members are served (Source: [ABAC - What is Consórcio](https://abac.org.br/o-consorcio/o-que-e-consorcio)).

</br>

Let's look at a simplified example of how it works:

Imagine you have the dream of owning your property, and it costs about 120 thousand dollars. Like you, many other people have this dream but don't have the money to purchase it immediately. You manage to gather a group of 100 people, so, every month, each one will contribute 1,200 dollars. Therefore, every month the group will have a fund of 1,200 (paid per person) x 100 (people in the group) = 120 thousand dollars.

To decide who will receive this entire amount, you do a draw. The person drawn receives the 120 thousand dollars and can fulfill their dream of buying a property. This person continues to pay the monthly 1,200 dollars. Also, the person who has already been drawn will no longer participate in future draws, as he has already been selected.

And so, the draws continue every month, until the entire group has been drawn.

With that, everyone in the group eventually manages to buy their property, but the order of who buys first is decided by draw. And no one needs to have all the money at once, as everyone contributes a little each month.

</br>

### 1.4. _Consórcio_ Advantages

- no need for a down payment, as is usually required in financing
- no need to provide guarantees until the moment of contemplation (or being "drawn"), making the adherence process simpler
- a wide variety of terms and values, allowing each client to choose what suits them best
- fixed terms
- low risk

</br>

## 2. Horizon Protocol

Horizon is a DEFI protocol aimed at simplifying access to the Web3 ecosystem, primarily for people with middle to low-income, making the process safer, more transparent, and auditable. With the imminent advancement of Tokenized Assets, we go further by implementing a logic that allows these Assets to be used as collateral for withdrawing the value of the acquired _Consórcio_ Title. 

To make this possible and to enable its use in various regions of the planet, in addition to the reliability of the Chainlink tools that will be used, the main barrier that needs to be overcome is the onboarding process, which until recently was restrictive due to the limited options of available Wallets. Today, we have a great ally in ERC-4337. And this is the first step towards changing the lives of many people.

</br>

Would you like to learn more about Tokenized Assets and ERC-4337? Access the links below:

- Real World Assets [RWA](https://www.coindesk.com/learn/rwa-tokenization-what-does-it-mean-to-tokenize-real-world-assets/)
  
- Account Abstraction [ERC-4337](https://www.erc4337.io)

</br>

### 2.1. The Prototype

This prototype simulates the following stages:

</br>

- [X] Creation of _Consórcio_ Titles
- [X] Commercialization of _Consórcio_ Quotas
- [X] Conducting _Consórcio_ Quota Lottery via VRF
- [X] Payments, Delays, and Application of Interest
- [X] Creation of Allocation Permissions through Chainlink CCIP
- [X] Verification of Guarantees
- [X] Allocation of Guarantees and Chainlink Automated Monitoring of Value following FIPE through Chainlink Functions

</br>

## 3. Tools Used

</br>

### 3.1. Chainlink VRF - Verifiable Random Function

Chainlink VRF is a crucial part of the protocol's operability, as the trust, transparency, and security provided by the tool are essential for all other functionalities to be performed correctly. The verifiable randomness, cryptographic security, decentralization, and integration with Smart Contracts make the results presented by the tool unquestionable.

</br>

### 3.2. Chainlink CCIP - Cross-Chain Interoperability Protocol

Chainlink CCIP allows Horizon to offer inclusion to diverse peoples and cultures by enabling communication between various blockchains and allowing the integration and use of assets from different parts of the globe in a secure and decentralized manner. Specifically, Horizon, will enable the creation of allocation permissions for guarantees on all Ethereum-compatible networks and, in the future, may integrate the protocol with specific networks of each country.

</br>

### 3.3. Chainlink Functions

Chainlink Functions will carry out the collection of necessary data for the allocation of Assets according to their respective off-chain databases. Furthermore, it could assist in the future with the implementation of liquidation measures or alerts to the respective owners of the assets allocated in the protocol.

It is responsible for collecting data through the FIPE API, bringing on-chain data of automobiles that will be used as examples of tokenized assets for guarantees.

</br>

### 3.4. Chainlink Automation - Chainlink’s hyper-reliable Automation network

Chainlink Automation is essential for the maintenance of the protocol. It will be responsible, along with Chainlink Functions, for the periodic collection of updated data from the allocated guarantees. This involves requesting the data and storing it based on the emitted response log. Thus, the protocol has mechanisms that ensure the health of the ecosystem.

Moreover, it could be used to conduct draws and automate processes for a possible new protocol stage.

</br>

### 3.5. Chainlink Tools Summary Table

Click on a function to check it on the code.

</br>

#### Chainlink VRF
|    Contract    |   Line   | Function               |   Go to  |
|----------------|----------|------------------------|----------|
|Horizon         |   495    | MonthlyVRFWinner       | [Check](https://github.com/BellumGalaxy/constellation-bg/blob/f7e3ff621dabdd0f98e700a06b631a2d8320fea6/contracts/Horizon.sol#L495)|
|Horizon VRF     |   83     | requestRandomWords     | [Check](https://github.com/BellumGalaxy/constellation-bg/blob/f7e3ff621dabdd0f98e700a06b631a2d8320fea6/contracts/HorizonVRF.sol#L83)|
|Horizon VRF     |   110    | fulfillRandomWords     | [Check](https://github.com/BellumGalaxy/constellation-bg/blob/f7e3ff621dabdd0f98e700a06b631a2d8320fea6/contracts/HorizonVRF.sol#L110)|
|Horizon         |   536    | ReceiveVRFRandomNumber | [Check](https://github.com/BellumGalaxy/constellation-bg/blob/f7e3ff621dabdd0f98e700a06b631a2d8320fea6/contracts/Horizon.sol#L536)|

</br>

#### Chainlink CCIP
|    Contract    |   Line   |       Function         |   Go to  |
|----------------|----------|------------------------|----------|
|Horizon         |   608    |    addRWACollateral    | [Check](https://github.com/BellumGalaxy/constellation-bg/blob/f7e3ff621dabdd0f98e700a06b631a2d8320fea6/contracts/Horizon.sol#L608)|
|Horizon         |   796    |      _ccipReceive      | [Check](https://github.com/BellumGalaxy/constellation-bg/blob/f7e3ff621dabdd0f98e700a06b631a2d8320fea6/contracts/Horizon.sol#L796)|
|HorizonS        |   70     |   sendMessagePayLINK   | [Check](https://github.com/BellumGalaxy/constellation-bg/blob/f7e3ff621dabdd0f98e700a06b631a2d8320fea6/contracts/HorizonS.sol#L70)|
|HorizonRFuji    |   131    |      _ccipReceive      | [Check](https://github.com/BellumGalaxy/constellation-bg/blob/f7e3ff621dabdd0f98e700a06b631a2d8320fea6/contracts/HorizonFujiR.sol#L131)|
|HorizonRFuji    |   219    |    addCollateral       | [Check](https://github.com/BellumGalaxy/constellation-bg/blob/f7e3ff621dabdd0f98e700a06b631a2d8320fea6/contracts/HorizonFujiR.sol#L219)|
|HorizonSFuji    |   63     |   sendMessagePayLINK   | [Check](https://github.com/BellumGalaxy/constellation-bg/blob/3035310d7f182e3b1ccda6764b2d7df2b0553ae2/contracts/HorizonFujiS.sol#L63)|

</br>

#### Chainlink Functions
|    Contract    |   Line   |        Function        |   Go to  |
|----------------|----------|------------------------|----------|
|HorizonRFuji    |   192    |  verifyCollateralValue | [Check](https://github.com/BellumGalaxy/constellation-bg/blob/f7e3ff621dabdd0f98e700a06b631a2d8320fea6/contracts/HorizonFujiR.sol#L192)|
|HorizonFunctions|   80     |       sendRequest      | [Check](https://github.com/BellumGalaxy/constellation-bg/blob/f7e3ff621dabdd0f98e700a06b631a2d8320fea6/contracts/HorizonFunctions.sol#L80)|
|HorizonFunctions|   111    |      fulfillRequest    | [Check](https://github.com/BellumGalaxy/constellation-bg/blob/f7e3ff621dabdd0f98e700a06b631a2d8320fea6/contracts/HorizonFunctions.sol#L111)|

</br>

#### Chainlink Automation
|     Contract   |   Line   |        Function        |   Go to  |
|----------------|----------|------------------------|----------|
|HorizonRFuji    |   289    |  checkCollateralPrice  | [Check](https://github.com/BellumGalaxy/constellation-bg/blob/f7e3ff621dabdd0f98e700a06b631a2d8320fea6/contracts/HorizonFujiR.sol#L289)|
|HorizonFunctions|   80     |       sendRequest      | [Check](https://github.com/BellumGalaxy/constellation-bg/blob/f7e3ff621dabdd0f98e700a06b631a2d8320fea6/contracts/HorizonFunctions.sol#L80)|
|HorizonRFuji    |   308    |   getCollateralPrice   | [Check](https://github.com/BellumGalaxy/constellation-bg/blob/f7e3ff621dabdd0f98e700a06b631a2d8320fea6/contracts/HorizonFujiR.sol#L308C14-L308C32)|

[Automation Log Registry](Automation-RG.pdf)

</br>

### 3.6. API - Application Programming Interface

Responsible for collecting information from the database of [FIPE](https://www.fipe.org.br) - Fundação Instituto de Pesquisas Econômicas (Foundation for Economic Research Institute).

</br>

## 4. Operation

The protocol is developed using smart contracts in Solidity. These contracts enable the Protocol Administration to create _Consórcio_ Titles of various values and durations. These _Consórcios_ have a limited number of participants and each _Consórcio_ has an interest policy against default. This is defined before their creation.

</br>

### 4.1. Commercialization of _Consórcio_ Titles

Upon acquiring a _Consórcio_ Quota, the client has two main options for withdrawal:

- Open Withdrawal 
   - Allows the client to withdraw the amount immediately after being drawn.</br>
   - Administration Fee: 10% of the Quota value, diluted monthly.

- Conditional Withdrawal
   - Withdrawal is only permitted after the Title exceeds the mark of 50% of the participants drawn.
   - Administration Fee: 5% of the Quota value, diluted in monthly installments.

</br>

For example, if the total number of draws is 10, withdrawal can only be made from draw 6 onwards, even if the client has been drawn earlier.

</br>

### 4.2. Investment of Received Funds

The funds received from Conditional Withdrawal titles will be invested in partner protocols to generate additional revenue for Horizon.

Objective: This process aims to enhance the financial sustainability of the protocol and offer better opportunities to participants.

</br>

### 4.3. Withdrawal Conditions

The withdrawal of a drawn _consórcio_ quota is not unrestricted. Withdrawal is conditional upon meeting one of the following conditions:

- Full Payment of the _Consórcio_ quota:
   </br>
  The total value of the quota must be paid.

- Allocation of Guarantees:
  </br>
  The client may choose to allocate guarantees to enable the withdrawal.


   - Use of Paid-Up or Partially Paid _Consórcio_ Quotas
     </br>
     Quotas that have been fully paid up or with an amount paid more than twice the outstanding value of the quota in which the guarantee will be allocated.
     
      Applicability:
      </br>
      This option is ideal for clients who possess other titles with significant payments already made.
   
   - Use of Tokenized Assets
     </br>
     Tokenized Assets can be used as collateral for withdrawal.

     Advantage:
     </br>
     Provides a flexible alternative for clients who own tokenized digital assets.

</br>

### 4.4. Allocation of Collaterals

After a Quota is drawn, the winner has the option to allocate guarantees to release the value. This allocation can be done in two main ways: using other titles or utilizing Tokenized Assets.

</br>

### 4.4.1. Allocation Process Using Titles

To use a title as collateral, the owner of the drawn title needs to provide some essential information:

- Identifier of the Drawn _Consórcio_ Title:
  </br>
  Identification number of the title that your quota was drawn.
  
- Identifier of Your Drawn Quota:
  </br>
  Number of your quota or participation in the drawn title.
  
- Identifier of the _Consórcio_ Title Used as Collateral:
  </br>
  Identification number of the title that the quota you wish to use as collateral.
  
- Identifier of Your Quota in the Collateral Title:
  </br>
  Number of your quota that will be used as collateral.

</br>

A Practical Example

* Drawn _Consórcio_ Title: 10
   * Your Quota in the Drawn _Consórcio_ Title: 30
* _Consórcio_ Title for Collateral: 5
   * Your Quota in the Collateral Title: 15

</br>

If the value of quota 15 from _Consórcio_ 5, used as collateral, meets the requirements, it will be transferred to the protocol, allocated as the guarantee for quota 30 of _Consórcio_ 10, and the prize amount will be released.

</br>

### 4.4.2. Allocation Using Tokenized Assets

Tokenized Assets are digital assets that represent ownership of a real or virtual property. They can be used as collateral in the following ways:

- Network Compatibility:
  </br>
  The Tokenized Asset can be allocated on any network compatible with the CCIP that Horizon operates.

- Value Assessment:
  </br>
  Before allocation, the value of the Tokenized Asset is assessed through Chainlink Functions and the FIPE API. If it is equivalent to or greater than the minimum value required for the _Consórcio_ quota, it will be accepted as collateral. <br/>

- Automated Monitoring:
  </br>
  After allocation, the value of the Tokenized Asset is automatically monitored. If there are significant variations in value, measures can be taken to maintain the integrity of the protocol.

</br>

### 4.5. _Consórcio_ Quota Withdrawal

The withdrawal of the Quota value is an important process in the Horizon protocol and can be performed under two main conditions:

- Full Payment of the Title:
  </br>
  Withdrawal is permitted after the full payment of the Quota value.
  
- Allocation of Guarantees:
  </br>
  If guarantees are allocated according to the protocol's rules, withdrawal is also released.

</br>

### 4.5.1. Withdrawal Process
Once one of the above conditions is met, the withdrawal process can be initiated:

- Owner's Initiative:
  </br>
  Typically, the quota owner initiates the withdrawal.
  
- Administrative Intervention:
  </br>
  In specific cases, the protocol administration can transfer the withdrawal value directly to the quota owner. This may occur for operational or exceptional reasons defined by the protocol. <br/>

</br>

### 4.5.2. Flexibility and Security
This withdrawal system has been designed to offer flexibility to users while maintaining the security and integrity of the protocol.

</br>

### 4.6. Management of Default and Interest

### 4.6.1. Payment Policy

- Payment Dates:
  </br>
  The payment dates for each _Consórcio_ Title are established at the time of their creation.
  
- Administrative Flexibility:
  </br>
  The protocol administration has the prerogative to postpone payment dates if necessary, but never to advance them.

</br>

### 4.6.2. Default and Interest Application

- Attention to Dates:
  </br>
  Clients must be attentive to payment dates to avoid default.
  
- Interest for Late Payment:
  </br>
  In case of payment delay, the pre-defined interest will be applied. These interest rates are established at the creation of the _Consórcio_ Title and aim to maintain the financial health of the protocol.

- Consequences of Default:
  </br>
  If the payment delay exceeds two installments, the _Consórcio_ quota will be considered default and subject to cancellation.

</br>

### 4.7. _Consórcio_ Quota Cancellation

- Cancellation Process:
  </br>
  The cancellation of a Quota is a last resource measure, applied only in cases of significant default.

- Impact of Cancellation:
  </br>
  The cancellation of a quota can have financial implications for the holder, including the loss of the payments already made.

</br> 

### 4.8. Penalty Policy

### 4.8.1. Purpose of Penalties

- Function of Penalties:
  </br>
  Penalties are applied in the event of a quota cancellation to ensure the stability of the protocol and to protect the interests of the other participants.

</br>

### 4.8.2. Penalties on Quotas without Allocated Guarantees

- Pre-Draw Cancellation:
  </br>
  If a quota is canceled before being drawn and does not have allocated guarantees, the amount already paid by the holder will be retained as a penalty.
  
- Purpose:
  </br>
  This measure aims to offset the financial impact of the cancellation on the overall fund pool.

</br>

### 4.8.3. Penalties on Quotas with Allocated Guarantees

- Post-Draw Cancellation with Guarantee:
  </br>
  For Quotas canceled after the draw, in which guarantees have already been allocated, the guarantee will be forfeited as a penalty.
  
- Treatment of the Guarantee:
  </br>
  The confiscated guarantee will be sold in the secondary market. The proceeds will be used to cover the penalty corresponding to the canceled quota.

</br>

### 4.8.4. Return of the Guarantee

After the settlement of all installments, the allocated guarantee is returned to the same address responsible for the allocation in the Quota.

</br>

## 5. _Consórcio_ Cost Projection

This is a simple and straightforward projection, covering only the costs of a single _Consórcio_ Title. We will not take into account the contract deployment costs.

The sources of the data used here are at the end of the document.

</br>

### 5.1. Objective

The purpose of this test is to demonstrate the feasibility of the protocol by practicing minimal administrative fees. </br>

For this projection, we consider the following information:

- Token value

   | Data  | Token   | Valor   |
   | ----- | ------- | ------- |
   | 07/12 | Matic   | $ 0,85  |
   | 07/12 | Link    | $ 15,73 |
   | 07/12 | BRLxUSD | R$ 4,91 |

</br>

### 5.2. _Consórcio_ Title - Matic

We consider a complete cycle of a _Consórcio_ with 100 installments.

| Action             | Cost in wei          | Calls | Total Wei Cost     |
| ------------------ | -------------------- | ----- | ------------------ |
| _Consórcio_ Creation | 0.02801992           | 1     | 0.02801992         |
| Selling opening    | 0.0207426017212544   | 1     | 0.0207426017212544 |
| Selling closing    | 0.0207426017212544   | 1     | 0.0207426017212544 |
| VRF Calls          | 0.00090366124154694  | 100   | 0.09036612         |
| Reveal Winner      | 0.000303593319049576 | 100   | 0.03035933         |
| Withdrawal         | 0.00018869           | 1     | 0.00018869         |

NOTE: The value in wei may vary depending on the network situation.

</br>

### 5.3. Chainlink Tools - Link

| Tool            | Value per call       | Calls | Total Wei Cost |
| --------------- | -------------------- | ----- | -------------- |
| VRF Link        | 0.000532970963743846 | 100   | 0.0532971      |
| CCIP Link       | 0.124037857          | 15    | 1.86056786     |
| Functions Link  | 0,210627978631381    | 3000  | 631.883936     |
| Automation Link | 0,0201923013272661   | 3000  | 60.576904      |

</br>

### 5.4. Total Cost - $

| Token | Wei Cost   | Value in $ | Total Cost - $ |
| ----- | ---------- | ---------- | -------------- |
| Matic | 0,19041927 | $0.85      | $ 0.16         |
| Link  | 694.374705 | $15.73     | $ 10,922.51    |

**Total cost:** $ 10,922.67

</br>

NOTE¹: According to records from the Central Bank of Brazil, under current conditions, only 5% of those drawn have allocated guarantees and made the withdrawal of the amount. Therefore, we consider 5 cycles of the CCIP. Each cycle has three calls.

NOTE²: Regarding the calls of Functions and Automation, we assume that the functions will be used from the first month. That is, the first winner would allocate a guarantee right in the first month, and we would monitor it daily until the payment of the 100 installments.

</br>

### 5.5. _Consórcio_ Title - Withdraw Modalities

| Modality             | Adm Fee |
| -------------------- | ------- |
| Open Withdraw        | 10%     |
| Conditional Withdraw | 5%      |

</br>

We will consider the average percentage of the amount withdrawn in 2022 as a parameter. Based on 2022 data, only 20% of the total amount moved was withdrawn. Therefore, we will only consider 20% of the _Consórcio_ in the Open Withdraw mode.

In other words:
Out of the 100 shares of this _Consórcio_, only 20 would be in the Open mode and, therefore, would pay a 10% administrative fee. The rest would be under the Conditional mode and, therefore, would contribute with a 5% administrative fee.

</br>

### 5.6. Average Ticket Practiced in Brazil

In Brazil, the average cost of Tickets is BRL 100.00. The average Administrative Fee is 17%.

So, converting the BRL value to USD:
R$ 100,00 / 4,91 = $ 20.36 ~ $ 20.00

</br>

### 5.7. Monthly income

Payments Monthly - **100x**

</br>

Open Withdraw Number of Payments - **20x**
Conditional Withdraw Number of Payments - **80x**

<br/>

Open Withdraw Payment Value - $ **21.00**
Conditional Withdraw Payment Value - $ **22.00**

</br>

Total Received from Open Withdraw - 20 _ $ 21.00 = $ **420.00**
Total Received from Conditional Withdraw - 80 _ $ 22.00 = $ **1,760.00**

</br>

Total Received Monthly - $ **2,180.00**

</br>

Total Installments - **100**

</br>

Total Received from Payments through the entire period of _Consórcio_ = $ 2,180.00 _ 100 = $ **218,000.00**
Total Paid to Participants through the entire period of _Consórcio_ = $2,000.00 _ 100 = $ **200,000.00**

</br>

Diff = $ **18,000.00**
Total Costs = $ **10,922.51**

</br>

Profit = $ **7,077.49**

</br>

### 5.8. Conclusion

Horizon has a great potential! Even practicing administrative fee two times smaller than the value practiced on web2.

Here, with this projection we don't consider interests from delayed payments or even the income from investments made with de value locked from Conditional Withdraw modality.

</br>

### 5.9. Research References

[Coinbase](https://www.coinbase.com/pt/)

[Central Bank of Brazil](https://www.bcb.gov.br/estabilidadefinanceira/consorciobd)

</br>

## 6. Evolution of the Protocol

Given the structure presented, the protocol has vast potential for growth and evolution. Among the points that have been discussed, we have:

</br>

### 6.1. Optimization of Phase 1

Given the billion-dollar market for investments of this nature, we need to reinforce our structure. This involves restructuring smart contracts for real environments, conducting audits, and redesigning UI and UX. Additionally, economic studies and local market analyses are crucial to gauge the challenges of expansion.

Measures such as developing classifications for accepted guarantees can reduce the final costs of the _Consórcio_. Therefore, cost management, adjustments of fees and penalties, processing of guarantees, more comprehensive studies, and targeted research can create new strategic advantages, always aiming for a better experience and greater opportunities for the end user. It is important to emphasize that beyond internal focus, we are aware that to expand our target audience we will also face legal challenges. 

</br>

### 6.2. Creation of a Secondary Market for the Commercialization of _Consórcio_ Quotas

With the creation of the Secondary Market, quota holders will have the freedom to trade them. This could involve reducing the quota price for a quick sale in case of need or even marking up the sale of a quota that has been drawn. From this, the protocol benefits from increased liquidity, as the market will be able to dynamically price the Quotas based on supply and demand, making the process fairer and more transparent. 

Moreover, it opens a door for clients to diversify their investment portfolio, reduces default, facilitates access for new participants, and stimulates participation since, despite having committed, a participant can transfer their Quota if necessary. 

Finally, the introduction of a secondary market can lead to additional innovations and the growth of the Horizon ecosystem, attracting more users and investors and enhancing the robustness and resilience of the system. 

</br>

### 6.3. Encouragement of Partnerships for the Creation of New Pools for Yield on Locked Values

Developing new partnerships can bring numerous strategic and operational benefits, expanding the reach of the Protocol. Among these, we have: 

- Access to new markets through other DeFi protocols or traditional finance significantly increases the number of users
  
- Expansion of Resources and Diversification of Investments, tailoring to regional supply and demand
  
- Long-term sustainability by providing stability and continuous innovation

</br>

### 6.4. Loan Services Using Tokenized Assets as Collateral

- Expands Horizon's scope to countries with lower interest rates where, initially, _consórcio_ would not be a viable option
  
- Facilitates access to short-term liquidity using Tokenized Assets
  
- Lower interest rates due to the allocated collateral
  
- Efficiency in the process
  
- Generates liquidity for the Tokenized Asset market
  
- Growth of the protocol as more assets are tokenized around the world

</br>

Chainlink Data Streams would be a crucial tool for the proper functioning of the protocol, as well as for monitoring Tokenized Assets.

</br>

### 6.5. Financing Using Tokenized Assets as Collateral

- Easy and quick access to capital, especially for entrepreneurs;
- Access to financing for large purchases such as real estate, furniture, and general equipment.
- Due to the guaranteed nature, we can offer favorable financing conditions such as lower interest rates and flexible repayment terms according to the need.

</br>

### 6.6. Our Thoughts
 
All the potential scenarios presented converge to efficient and transparent processes through the employed technology and generate financial inclusion for individuals and businesses that lack access to loans from traditional institutions but have assets and need to create value from them.

In summary, the initial product and its possible developments are not only useful for investors but also for people who, in times of need, can meet specific demands such as health issues by acquiring loans and financing quickly and conveniently using their assets as collateral.

</br>

## 7. Conclusion

Horizon represents a significant advancement in democratizing access to the Web3 ecosystem, with a special focus on the financial inclusion of middle and low-income individuals. By integrating innovative technologies such as Chainlink VRF, CCIP, Functions, and Automation, and the integration with the FIPE Table, Horizon establishes a new standard in terms of security, transparency, and auditability in decentralized financial operations. <br/>

Through the implementation of a robust _consórcio_ system, Horizon not only facilitates the acquisition of goods and services but also paves the way for the efficient use of Tokenized Assets as collateral, expanding the possibilities for withdrawal and investment for users. This aspect is particularly revolutionary as it leverages the potential of digital assets in a way that directly benefits the end-user while maintaining the integrity and sustainability of the system. <br/>

Furthermore, Horizon's structure is designed to evolve and adapt to the emerging needs of the market and users. With plans that include the creation of a secondary market for titles, exploring partnerships for additional yields, and expanding into loan and financing services, Horizon is not just a solution for the present but an investment in the future of decentralized finance. <br/>

</br>

## 8. Developer Session

### 8.1. Smart contracts

- [Horizon](contracts/Horizon.sol)

- [HorizonS](contracts/HorizonS.sol)

- [HorizonStaff](contracts/HorizonStaff.sol)

- [HorizonVRF](contracts/HorizonVRF.sol)

- [HorizonFujiR](contracts/HorizonFujiR.sol)

- [HorizonFujiS](contracts/HorizonFujiS.sol)

- [HorizonFunctions](contracts/HorizonFunctions.sol)

- [HorizonFujiAssistant](contracts/HorizonFujiAssistant.sol)

- [FakeRWA](contracts/FakeRWA.sol)

</br>

### 8.2. Blockchains

- [Polygon](https://polygon.technology)

- [Avalanche](https://www.avax.network)

</br>

### 8.3. Tools

- [Chainlink Automation](https://docs.chain.link/chainlink-automation)

- [Chainlink CCIP](https://docs.chain.link/ccip)

- [Chainlink Functions](https://docs.chain.link/chainlink-functions)

- [Chainlink VRF](https://docs.chain.link/vrf)

</br>

### 8.4. API

- [API GitHub Repository](https://github.com/deividfortuna/fipe)

- API_Key:
  </br>     https://parallelum.com.br/fipe/api/v1/${tipoAutomovel}/marcas/${idMarca}/modelos/${idModelo}/anos/${dataModelo}

- Input used in demo:
  </br>
  ```["motos","77","5223","2015-1"]```

</br>

### 7.5. Want to try Thunder Client?

- Body
  </br>
  ```
  {
  "codigoTipoVeiculo": motos,
  "idMarca": 77,
  "idModelo": 5223,
  "dataModelo": "2015-1",
  }
  ```

- Response
  </br>
  ```
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
  ```
  
