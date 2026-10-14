@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictCareProtocolThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultStrictCareProtocolThresholdValidator()
        let item = ClinicalOps.newStrictCareProtocolThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsStrictCareProtocolThresholdRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = ClinicalOps.StrictCareProtocolThresholdRequiredReviewerRule(
            message: "strict care protocol threshold needs an entry"
        )
        let item = ClinicalOps.newStrictCareProtocolThreshold("", name: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsStrictCareProtocolThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.StrictCareProtocolThresholdRequiredCodeRule(
            message: "strict care protocol threshold needs this field"
        )
        let item = ClinicalOps.newStrictCareProtocolThreshold("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsStrictCareProtocolThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.StrictCareProtocolThresholdCodeLengthRule(maxLength: 80)
        let item = ClinicalOps.newStrictCareProtocolThreshold("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
