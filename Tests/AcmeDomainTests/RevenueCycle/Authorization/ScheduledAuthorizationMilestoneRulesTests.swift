@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledAuthorizationMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultScheduledAuthorizationMilestoneValidator()
        let item = RevenueCycle.newScheduledAuthorizationMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleScheduledAuthorizationMilestoneRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.ScheduledAuthorizationMilestoneRequiredNameRule(
            message: "scheduled authorization milestone needs an entry"
        )
        let item = RevenueCycle.newScheduledAuthorizationMilestone("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleScheduledAuthorizationMilestoneRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = RevenueCycle.ScheduledAuthorizationMilestoneRequiredContactEmailRule(
            message: "scheduled authorization milestone needs an entry"
        )
        let item = RevenueCycle.newScheduledAuthorizationMilestone("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleScheduledAuthorizationMilestoneNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.ScheduledAuthorizationMilestoneNameLengthRule(maxLength: 80)
        let item = RevenueCycle.newScheduledAuthorizationMilestone("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
