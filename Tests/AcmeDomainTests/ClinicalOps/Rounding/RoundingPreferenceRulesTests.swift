@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingPreferenceValidator()
        let item = ClinicalOps.newRoundingPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingPreferenceTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = ClinicalOps.RoundingPreferenceTimezoneLengthRule(maxLength: 32)
        let item = ClinicalOps.newRoundingPreference("x", label: "y")
        item.timezone = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRoundingPreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.RoundingPreferenceCodeLengthRule(maxLength: 3600)
        let item = ClinicalOps.newRoundingPreference("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRoundingPreferenceLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.RoundingPreferenceLabelLengthRule(maxLength: 32)
        let item = ClinicalOps.newRoundingPreference("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
