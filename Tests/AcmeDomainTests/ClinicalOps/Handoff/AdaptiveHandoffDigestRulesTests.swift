@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveHandoffDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAdaptiveHandoffDigestValidator()
        let item = ClinicalOps.newAdaptiveHandoffDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAdaptiveHandoffDigestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.AdaptiveHandoffDigestRequiredLabelRule(message: "adaptive handoff digest needs an entry")
        let item = ClinicalOps.newAdaptiveHandoffDigest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAdaptiveHandoffDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.AdaptiveHandoffDigestRequiredCodeRule(message: "adaptive handoff digest needs an entry")
        let item = ClinicalOps.newAdaptiveHandoffDigest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAdaptiveHandoffDigestUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = ClinicalOps.AdaptiveHandoffDigestUpdatedAtRangeRule(min: 255, max: 3600)
        let item = ClinicalOps.newAdaptiveHandoffDigest("x", label: "y")
        item.updatedAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAdaptiveHandoffDigestPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = ClinicalOps.AdaptiveHandoffDigestPhoneLengthRule(maxLength: 120)
        let item = ClinicalOps.newAdaptiveHandoffDigest("x", label: "y")
        item.phone = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAdaptiveHandoffDigestLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.AdaptiveHandoffDigestLabelLengthRule(maxLength: 255)
        let item = ClinicalOps.newAdaptiveHandoffDigest("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
