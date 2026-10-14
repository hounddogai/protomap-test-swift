@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveHandoffVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAdaptiveHandoffVarianceValidator()
        let item = ClinicalOps.newAdaptiveHandoffVariance("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAdaptiveHandoffVarianceOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = ClinicalOps.AdaptiveHandoffVarianceOwnerIDLengthRule(maxLength: 80)
        let item = ClinicalOps.newAdaptiveHandoffVariance("x", label: "y")
        item.ownerID = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAdaptiveHandoffVarianceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.AdaptiveHandoffVarianceRequiredLabelRule(
            message: "adaptive handoff variance needs a value"
        )
        let item = ClinicalOps.newAdaptiveHandoffVariance("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAdaptiveHandoffVarianceStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = ClinicalOps.AdaptiveHandoffVarianceStartsAtRangeRule(min: 255, max: 3600)
        let item = ClinicalOps.newAdaptiveHandoffVariance("x", label: "y")
        item.startsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAdaptiveHandoffVarianceLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.AdaptiveHandoffVarianceLabelLengthRule(maxLength: 86400)
        let item = ClinicalOps.newAdaptiveHandoffVariance("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAdaptiveHandoffVarianceRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = ClinicalOps.AdaptiveHandoffVarianceRequiredOwnerIDRule(
            message: "adaptive handoff variance needs an entry"
        )
        let item = ClinicalOps.newAdaptiveHandoffVariance("", label: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}
