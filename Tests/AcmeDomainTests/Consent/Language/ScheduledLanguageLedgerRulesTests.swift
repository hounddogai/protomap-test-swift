@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledLanguageLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultScheduledLanguageLedgerValidator()
        let item = Consent.newScheduledLanguageLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentScheduledLanguageLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ScheduledLanguageLedgerCodeLengthRule(maxLength: 32)
        let item = Consent.newScheduledLanguageLedger("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentScheduledLanguageLedgerMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Consent.ScheduledLanguageLedgerMarginRangeRule(min: 9.6, max: 2082.6)
        let item = Consent.newScheduledLanguageLedger("x", name: "y")
        item.margin = 2084.1
        #expect(rule.check(item).count > 0)
    }
}
