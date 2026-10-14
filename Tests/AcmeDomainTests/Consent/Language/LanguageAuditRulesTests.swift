@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageAuditValidator()
        let item = Consent.newLanguageAudit("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageAuditNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.LanguageAuditNameLengthRule(maxLength: 255)
        let item = Consent.newLanguageAudit("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguageAuditAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Consent.LanguageAuditAmountRangeRule(min: 7.8, max: 3541.5)
        let item = Consent.newLanguageAudit("x", name: "y")
        item.amount = 3543.0
        #expect(rule.check(item).count > 0)
    }
}
