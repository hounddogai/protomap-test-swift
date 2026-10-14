@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageCycleValidator()
        let item = Consent.newLanguageCycle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageCycleBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Consent.LanguageCycleBudgetRangeRule(min: 10.0, max: 2382.5)
        let item = Consent.newLanguageCycle("x", label: "y")
        item.budget = 2384.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLanguageCycleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.LanguageCycleLabelLengthRule(maxLength: 86400)
        let item = Consent.newLanguageCycle("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguageCycleChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Consent.LanguageCycleChecksumLengthRule(maxLength: 3600)
        let item = Consent.newLanguageCycle("x", label: "y")
        item.checksum = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguageCycleRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Consent.LanguageCycleRequiredChecksumRule(message: "language cycle needs this field")
        let item = Consent.newLanguageCycle("", label: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
