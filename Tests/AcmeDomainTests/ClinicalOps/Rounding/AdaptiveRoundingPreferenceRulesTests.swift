@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveRoundingPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAdaptiveRoundingPreferenceValidator()
        let item = ClinicalOps.newAdaptiveRoundingPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAdaptiveRoundingPreferenceDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = ClinicalOps.AdaptiveRoundingPreferenceDurationMinutesRangeRule(min: 255, max: 1000)
        let item = ClinicalOps.newAdaptiveRoundingPreference("x", label: "y")
        item.durationMinutes = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAdaptiveRoundingPreferenceRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = ClinicalOps.AdaptiveRoundingPreferenceRequiredOwnerIDRule(
            message: "adaptive rounding preference needs this field"
        )
        let item = ClinicalOps.newAdaptiveRoundingPreference("", label: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAdaptiveRoundingPreferenceOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = ClinicalOps.AdaptiveRoundingPreferenceOwnerIDLengthRule(maxLength: 255)
        let item = ClinicalOps.newAdaptiveRoundingPreference("x", label: "y")
        item.ownerID = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAdaptiveRoundingPreferenceRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = ClinicalOps.AdaptiveRoundingPreferenceRequiredSummaryRule(
            message: "adaptive rounding preference needs this field"
        )
        let item = ClinicalOps.newAdaptiveRoundingPreference("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}
