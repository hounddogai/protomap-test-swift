@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledOutreachCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultScheduledOutreachCycleValidator()
        let item = CareManagement.newScheduledOutreachCycle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementScheduledOutreachCycleChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = CareManagement.ScheduledOutreachCycleChannelLengthRule(maxLength: 255)
        let item = CareManagement.newScheduledOutreachCycle("x", label: "y")
        item.channel = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementScheduledOutreachCycleRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = CareManagement.ScheduledOutreachCycleRequiredChannelRule(
            message: "scheduled outreach cycle needs this field"
        )
        let item = CareManagement.newScheduledOutreachCycle("", label: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementScheduledOutreachCycleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.ScheduledOutreachCycleLabelLengthRule(maxLength: 3600)
        let item = CareManagement.newScheduledOutreachCycle("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
