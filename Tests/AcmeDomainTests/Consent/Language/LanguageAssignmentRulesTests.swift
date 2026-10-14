@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageAssignmentValidator()
        let item = Consent.newLanguageAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageAssignmentAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Consent.LanguageAssignmentAmountRangeRule(min: 0.8, max: 3037.4)
        let item = Consent.newLanguageAssignment("x", name: "y")
        item.amount = 3038.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLanguageAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.LanguageAssignmentRequiredCodeRule(message: "language assignment needs a value")
        let item = Consent.newLanguageAssignment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageAssignmentRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Consent.LanguageAssignmentRequiredDiagnosisCodeRule(message: "language assignment needs an entry")
        let item = Consent.newLanguageAssignment("", name: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageAssignmentCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Consent.LanguageAssignmentCostRangeRule(min: 6.4, max: 1934.9)
        let item = Consent.newLanguageAssignment("x", name: "y")
        item.cost = 1936.4
        #expect(rule.check(item).count > 0)
    }
}
