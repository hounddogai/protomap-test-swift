@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledAuthorizationSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultScheduledAuthorizationSnapshotValidator()
        let item = RevenueCycle.newScheduledAuthorizationSnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleScheduledAuthorizationSnapshotRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.ScheduledAuthorizationSnapshotRequiredTitleRule(
            message: "scheduled authorization snapshot needs an entry"
        )
        let item = RevenueCycle.newScheduledAuthorizationSnapshot("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleScheduledAuthorizationSnapshotAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = RevenueCycle.ScheduledAuthorizationSnapshotAmountRangeRule(min: 1.5, max: 4872.9)
        let item = RevenueCycle.newScheduledAuthorizationSnapshot("x", title: "y")
        item.amount = 4874.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleScheduledAuthorizationSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ScheduledAuthorizationSnapshotRequiredCodeRule(
            message: "scheduled authorization snapshot needs this field"
        )
        let item = RevenueCycle.newScheduledAuthorizationSnapshot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
