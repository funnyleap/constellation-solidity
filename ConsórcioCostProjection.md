# About this projection

This is a simple and straightforward projection, covering only the costs of a single Consórcio Title. We will not take into account the contract deployment costs.

</br>

The sources of the data used here will be provided at the end of the document.

# Objective

The purpose of this test is to demonstrate the feasibility of the protocol by practicing minimal administrative fees. </br>

For this projection, we consider the following information:

## Token value

| Data  | Token   | Valor   |
| ----- | ------- | ------- |
| 07/12 | Matic   | $ 0,85  |
| 07/12 | Link    | $ 15,73 |
| 07/12 | BRLxUSD | R$ 4,91 |

## Consórcio Title - Matic

We consider a complete cycle of a Consórcio with 100 installments.

| Action             | Cost in wei          | Calls | Total Wei Cost     |
| ------------------ | -------------------- | ----- | ------------------ |
| Consórcio Creation | 0.02801992           | 1     | 0.02801992         |
| Selling opening    | 0.0207426017212544   | 1     | 0.0207426017212544 |
| Selling closing    | 0.0207426017212544   | 1     | 0.0207426017212544 |
| VRF Calls          | 0.00090366124154694  | 100   | 0.09036612         |
| Reveal Winner      | 0.000303593319049576 | 100   | 0.03035933         |
| Withdrawal         | 0.00018869           | 1     | 0.00018869         |

NOTE: The value in wei may vary depending on the network situation.

## Chainlink Tools - Link

| Tool            | Value per call       | Calls | Total Wei Cost |
| --------------- | -------------------- | ----- | -------------- |
| VRF Link        | 0.000532970963743846 | 100   | 0.0532971      |
| CCIP Link       | 0.124037857          | 15    | 1.86056786     |
| Functions Link  | 0,210627978631381    | 3000  | 631.883936     |
| Automation Link | 0,0201923013272661   | 3000  | 60.576904      |

## Total Cost - $

| Token | Wei Cost   | Value in $ | Total Cost - $ |
| ----- | ---------- | ---------- | -------------- |
| Matic | 0,19041927 | $0.85      | $ 0.16         |
| Link  | 694.374705 | $15.73     | $ 10,922.51    |

**Total cost:** $ 10,922.67

NOTE¹: According to records from the Central Bank of Brazil, under current conditions, only 5% of those drawn have allocated guarantees and made the withdrawal of the amount. Therefore, we consider 5 cycles of the CCIP. Each cycle has three calls.

</br>

NOTE²: Regarding the calls of Functions and Automation, we assume that the functions will be used from the first month. That is, the first winner would allocate a guarantee right in the first month, and we would monitor it daily until the payment of the 100 installments.

## Consórcio Title - Withdraw Modalities

| Modality             | Adm Fee |
| -------------------- | ------- |
| Open Withdraw        | 10%     |
| Conditional Withdraw | 5%      |

We will consider the average percentage of the amount withdrawn in 2022 as a parameter. Based on 2022 data, only 20% of the total amount moved was withdrawn. Therefore, we will only consider 20% of the Consórcio in the Open Withdraw mode.

</br>

In other words:
Out of the 100 shares of this Consórcio, only 20 would be in the Open mode and, therefore, would pay a 10% administrative fee. The rest would be under the Conditional mode and, therefore, would contribute with a 5% administrative fee.

## Average Ticket Practiced in Brazil

In Brazil, the average cost of Tickets is BRL 100.00. The average Administrative Fee is 17%.

So, converting the BRL value to USD:
R$ 100,00 / 4,91 = $ 20.36 ~ $ 20.00

## Monthly income

Payments Monthly - **100x**

Open Withdraw Number of Payments - **20x**
Conditional Withdraw Number of Payments - **80x**

Open Withdraw Payment Value - $ **21.00**
Conditional Withdraw Payment Value - $ **22.00**

Total Received from Open Withdraw - 20 _ $ 21.00 = $ **420.00**
Total Received from Conditional Withdraw - 80 _ $ 22.00 = $ **1,760.00**

Total Received Monthly - $ **2,180.00**

Total Installments - **100**

Total Received from Payments through the entire period of Consórcio = $ 2,180.00 _ 100 = $ **218,000.00**
Total Paid to Participants through the entire period of Consórcio = $2,000.00 _ 100 = $ **200,000.00**

Diff = $ **18,000.00**
Total Costs = $ **10,922.51**

Profit = $ **7,077.49**

## Conclusion

Horizon has a great potential! Even practicing administrative fee two times smaller than the value practiced on web2.

Here, with this projection we don't consider interests from delayed payments or even the income from investments made with de value locked from Conditional Withdraw modality.

# Research References

[Coinbase](https://www.coinbase.com/pt/)
[Central Bank of Brazil](https://www.bcb.gov.br/estabilidadefinanceira/consorciobd)
