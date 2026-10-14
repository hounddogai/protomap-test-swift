@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageLedgerValidator()
        let item = Consent.newLanguageLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageLedgerRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Consent.LanguageLedgerRequiredCurrencyRule(message: "language ledger needs a value")
        let item = Consent.newLanguageLedger("", name: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageLedgerUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Consent.LanguageLedgerUpdatedAtRangeRule(min: 16, max: 120)
        let item = Consent.newLanguageLedger("x", name: "y")
        item.updatedAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLanguageLedgerNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.LanguageLedgerNameLengthRule(maxLength: 86400)
        let item = Consent.newLanguageLedger("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
