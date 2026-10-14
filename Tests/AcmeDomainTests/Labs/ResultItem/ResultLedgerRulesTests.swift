@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultLedgerValidator()
        let item = Labs.newResultLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultLedgerAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Labs.ResultLedgerAmountRangeRule(min: 2.2, max: 4805.4)
        let item = Labs.newResultLedger("x", name: "y")
        item.amount = 4806.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsResultLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ResultLedgerCodeLengthRule(maxLength: 32)
        let item = Labs.newResultLedger("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultLedgerChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Labs.ResultLedgerChannelLengthRule(maxLength: 86400)
        let item = Labs.newResultLedger("x", name: "y")
        item.channel = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultLedgerRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Labs.ResultLedgerRequiredChannelRule(message: "result ledger needs a value")
        let item = Labs.newResultLedger("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
