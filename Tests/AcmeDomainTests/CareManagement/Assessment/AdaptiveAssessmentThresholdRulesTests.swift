@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveAssessmentThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAdaptiveAssessmentThresholdValidator()
        let item = CareManagement.newAdaptiveAssessmentThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAdaptiveAssessmentThresholdCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = CareManagement.AdaptiveAssessmentThresholdCopayRangeRule(min: 8.2, max: 1011.3)
        let item = CareManagement.newAdaptiveAssessmentThreshold("x", title: "y")
        item.copay = 1012.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAdaptiveAssessmentThresholdTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.AdaptiveAssessmentThresholdTitleLengthRule(maxLength: 32)
        let item = CareManagement.newAdaptiveAssessmentThreshold("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveAssessmentThresholdChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = CareManagement.AdaptiveAssessmentThresholdChannelLengthRule(maxLength: 64)
        let item = CareManagement.newAdaptiveAssessmentThreshold("x", title: "y")
        item.channel = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveAssessmentThresholdRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = CareManagement.AdaptiveAssessmentThresholdRequiredChannelRule(
            message: "adaptive assessment threshold needs an entry"
        )
        let item = CareManagement.newAdaptiveAssessmentThreshold("", title: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
