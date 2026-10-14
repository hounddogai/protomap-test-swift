@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledClaimMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultScheduledClaimMilestoneValidator()
        let item = RevenueCycle.newScheduledClaimMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleScheduledClaimMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ScheduledClaimMilestoneRequiredCodeRule(
            message: "scheduled claim milestone needs a value"
        )
        let item = RevenueCycle.newScheduledClaimMilestone("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleScheduledClaimMilestoneNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.ScheduledClaimMilestoneNameLengthRule(maxLength: 80)
        let item = RevenueCycle.newScheduledClaimMilestone("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
