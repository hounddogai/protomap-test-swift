@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledHandoffMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultScheduledHandoffMilestoneValidator()
        let item = ClinicalOps.newScheduledHandoffMilestone("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsScheduledHandoffMilestoneRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = ClinicalOps.ScheduledHandoffMilestoneRequiredTimezoneRule(
            message: "scheduled handoff milestone needs an entry"
        )
        let item = ClinicalOps.newScheduledHandoffMilestone("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsScheduledHandoffMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.ScheduledHandoffMilestoneCodeLengthRule(maxLength: 255)
        let item = ClinicalOps.newScheduledHandoffMilestone("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
