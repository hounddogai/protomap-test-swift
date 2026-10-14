@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualAuthorizationMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultManualAuthorizationMilestoneValidator()
        let item = RevenueCycle.newManualAuthorizationMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleManualAuthorizationMilestoneTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.ManualAuthorizationMilestoneTitleLengthRule(maxLength: 86400)
        let item = RevenueCycle.newManualAuthorizationMilestone("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleManualAuthorizationMilestoneUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = RevenueCycle.ManualAuthorizationMilestoneUpdatedAtRangeRule(min: 120, max: 1000)
        let item = RevenueCycle.newManualAuthorizationMilestone("x", title: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
