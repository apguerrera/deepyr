# OAX Swim Gateway Stable Coin Contract Audit

Status: Work in progress

## Summary

[BokkyPooBah](https://www.bokconsulting.com.au/) has developed a smart contract library and wrapper contract for gas efficient calculation of date and time on Ethereum.

[Deepyr Pty Ltd](https://www.deepyr.com) was commissioned to perform an audit on these Ethereum smart contracts.

This audit has been conducted on the source code from [apguerrera/](https://github.com/apguerrera/) in commits [75cc80c](https://github.com/apguerrera)

**TODO** Check that no potential vulnerabilities have been identified in the smart contracts.

<br />

<hr />

## Table Of Contents

* [Summary](#summary)
* [Recommendations](#recommendations)
* [Potential Vulnerabilities](#potential-vulnerabilities)
* [Scope](#scope)
* [Risks](#risks)
* [Testing](#testing)
* [Code Review](#code-review)

<br />

<hr />

## Recommendations

* [ ] **LOW IMPORTANCE** Set `File:Contract.function` to *public*

<br />

<hr />

## Potential Vulnerabilities

**TODO** Check that no potential vulnerabilities have been identified in the smart contracts.

<br />

<hr />

## Scope

This audit is into the technical aspects of the smart contracts. The primary aim of this audit is to ensure that funds
stored in these contracts are not easily attacked or stolen by third parties. The secondary aim of this audit is to
ensure the coded algorithms work as expected. This audit does not guarantee that that the code is bugfree, but intends to
highlight any areas of weaknesses.

<br />

<hr />

## Risks

**TODO**

<br />

<hr />

## Testing

Details of the testing environment can be found in [test](test).

[../chain/index.js](../chain/index.js) and [../chain/lib/deployerProd.js](../chain/lib/deployerProd.js) were used as a guide for the security model used with this set of contracts.

The following functions were tested using the script [test/01_test1.sh](test/01_test1.sh) with the summary results saved
in [test/test1results.txt](test/test1results.txt) and the detailed output saved in [test/test1output.txt](test/test1output.txt):

* [x] Group #1 deployment
  * [] `Contract()`


<br />

<hr />

## Code Review

* [ ] [code-review/Contract.md](code-review/Contract.md)
  * [ ] contract Contract


<br />



### Outside Scope

* Things that are out of scope

<br />

<br />

(c) Adrian Guerrera / Deepyr Pty Ltd for BokkyPooBah / Bok Consulting Pty Ltd - Aug 30 2018. The MIT Licence.
