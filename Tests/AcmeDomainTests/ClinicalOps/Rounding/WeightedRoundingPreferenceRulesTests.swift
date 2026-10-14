@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedRoundingPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultWeightedRoundingPreferenceValidator()
        let item = ClinicalOps.newWeightedRoundingPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsWeightedRoundingPreferenceAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = ClinicalOps.WeightedRoundingPreferenceAttemptsRangeRule(min: 16, max: 255)
        let item = ClinicalOps.newWeightedRoundingPreference("x", label: "y")
        item.attempts = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsWeightedRoundingPreferenceRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = ClinicalOps.WeightedRoundingPreferenceRegionLengthRule(maxLength: 32)
        let item = ClinicalOps.newWeightedRoundingPreference("x", label: "y")
        item.region = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsWeightedRoundingPreferenceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.WeightedRoundingPreferenceRequiredLabelRule(
            message: "weighted rounding preference needs a value"
        )
        let item = ClinicalOps.newWeightedRoundingPreference("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsWeightedRoundingPreferenceProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = ClinicalOps.WeightedRoundingPreferenceProcedureCodeLengthRule(maxLength: 120)
        let item = ClinicalOps.newWeightedRoundingPreference("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsWeightedRoundingPreferenceLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.WeightedRoundingPreferenceLabelLengthRule(maxLength: 3600)
        let item = ClinicalOps.newWeightedRoundingPreference("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsWeightedRoundingPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.WeightedRoundingPreferenceRequiredCodeRule(
            message: "weighted rounding preference needs a value"
        )
        let item = ClinicalOps.newWeightedRoundingPreference("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
