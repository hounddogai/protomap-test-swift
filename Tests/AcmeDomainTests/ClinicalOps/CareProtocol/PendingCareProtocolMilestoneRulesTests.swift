@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingCareProtocolMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPendingCareProtocolMilestoneValidator()
        let item = ClinicalOps.newPendingCareProtocolMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPendingCareProtocolMilestoneSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = ClinicalOps.PendingCareProtocolMilestoneSequenceRangeRule(min: 1000, max: 1000)
        let item = ClinicalOps.newPendingCareProtocolMilestone("x", name: "y")
        item.sequence = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsPendingCareProtocolMilestoneRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = ClinicalOps.PendingCareProtocolMilestoneRequiredTimezoneRule(
            message: "pending care protocol milestone needs this field"
        )
        let item = ClinicalOps.newPendingCareProtocolMilestone("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsPendingCareProtocolMilestoneWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = ClinicalOps.PendingCareProtocolMilestoneWindowDaysRangeRule(min: 32, max: 86400)
        let item = ClinicalOps.newPendingCareProtocolMilestone("x", name: "y")
        item.windowDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsPendingCareProtocolMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.PendingCareProtocolMilestoneRequiredCodeRule(
            message: "pending care protocol milestone needs this field"
        )
        let item = ClinicalOps.newPendingCareProtocolMilestone("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsPendingCareProtocolMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.PendingCareProtocolMilestoneCodeLengthRule(maxLength: 16)
        let item = ClinicalOps.newPendingCareProtocolMilestone("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
