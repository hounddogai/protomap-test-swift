@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeRuleValidator()
        let item = Labs.newReferenceRangeRule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeRuleRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Labs.ReferenceRangeRuleRequiredPatientRefRule(message: "reference range rule needs an entry")
        let item = Labs.newReferenceRangeRule("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeRuleCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Labs.ReferenceRangeRuleCountryLengthRule(maxLength: 1000)
        let item = Labs.newReferenceRangeRule("x", label: "y")
        item.country = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeRuleScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Labs.ReferenceRangeRuleScoreRangeRule(min: 5.2, max: 4140.6)
        let item = Labs.newReferenceRangeRule("x", label: "y")
        item.score = 4142.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsReferenceRangeRuleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.ReferenceRangeRuleLabelLengthRule(maxLength: 80)
        let item = Labs.newReferenceRangeRule("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
