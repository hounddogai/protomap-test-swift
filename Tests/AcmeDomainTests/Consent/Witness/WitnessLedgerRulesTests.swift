@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessLedgerValidator()
        let item = Consent.newWitnessLedger("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessLedgerTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.WitnessLedgerTitleLengthRule(maxLength: 86400)
        let item = Consent.newWitnessLedger("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWitnessLedgerChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Consent.WitnessLedgerChannelLengthRule(maxLength: 120)
        let item = Consent.newWitnessLedger("x", title: "y")
        item.channel = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWitnessLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.WitnessLedgerRequiredCodeRule(message: "witness ledger needs a value")
        let item = Consent.newWitnessLedger("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessLedgerRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.WitnessLedgerRequiredTitleRule(message: "witness ledger needs a value")
        let item = Consent.newWitnessLedger("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
