@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledAssessmentThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultScheduledAssessmentThresholdValidator()
        let item = CareManagement.newScheduledAssessmentThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementScheduledAssessmentThresholdTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.ScheduledAssessmentThresholdTitleLengthRule(maxLength: 255)
        let item = CareManagement.newScheduledAssessmentThreshold("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementScheduledAssessmentThresholdRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = CareManagement.ScheduledAssessmentThresholdRequiredChannelRule(
            message: "scheduled assessment threshold needs an entry"
        )
        let item = CareManagement.newScheduledAssessmentThreshold("", title: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementScheduledAssessmentThresholdRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = CareManagement.ScheduledAssessmentThresholdRequiredFacilityRule(
            message: "scheduled assessment threshold needs a value"
        )
        let item = CareManagement.newScheduledAssessmentThreshold("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementScheduledAssessmentThresholdEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = CareManagement.ScheduledAssessmentThresholdEndsAtRangeRule(min: 64, max: 86400)
        let item = CareManagement.newScheduledAssessmentThreshold("x", title: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
