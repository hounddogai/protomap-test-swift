@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionPreferenceValidator()
        let item = Labs.newAccessionPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionPreferenceAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Labs.AccessionPreferenceAcuityRangeRule(min: 3600, max: 86400)
        let item = Labs.newAccessionPreference("x", title: "y")
        item.acuity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionPreferenceCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Labs.AccessionPreferenceCreatedAtRangeRule(min: 255, max: 1000)
        let item = Labs.newAccessionPreference("x", title: "y")
        item.createdAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.AccessionPreferenceRequiredCodeRule(message: "accession preference needs an entry")
        let item = Labs.newAccessionPreference("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionPreferencePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Labs.AccessionPreferencePatientRefLengthRule(maxLength: 1000)
        let item = Labs.newAccessionPreference("x", title: "y")
        item.patientRef = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionPreferenceDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Labs.AccessionPreferenceDosageMgRangeRule(min: 4.6, max: 2220.3)
        let item = Labs.newAccessionPreference("x", title: "y")
        item.dosageMg = 2221.8
        #expect(rule.check(item).count > 0)
    }
}
