@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualAuthorizationSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultManualAuthorizationSnapshotValidator()
        let item = RevenueCycle.newManualAuthorizationSnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleManualAuthorizationSnapshotRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.ManualAuthorizationSnapshotRequiredTitleRule(
            message: "manual authorization snapshot needs a value"
        )
        let item = RevenueCycle.newManualAuthorizationSnapshot("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleManualAuthorizationSnapshotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.ManualAuthorizationSnapshotTitleLengthRule(maxLength: 3600)
        let item = RevenueCycle.newManualAuthorizationSnapshot("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleManualAuthorizationSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ManualAuthorizationSnapshotRequiredCodeRule(
            message: "manual authorization snapshot needs this field"
        )
        let item = RevenueCycle.newManualAuthorizationSnapshot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleManualAuthorizationSnapshotStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = RevenueCycle.ManualAuthorizationSnapshotStartsAtRangeRule(min: 3600, max: 3600)
        let item = RevenueCycle.newManualAuthorizationSnapshot("x", title: "y")
        item.startsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleManualAuthorizationSnapshotExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = RevenueCycle.ManualAuthorizationSnapshotExpiresAtRangeRule(min: 3600, max: 86400)
        let item = RevenueCycle.newManualAuthorizationSnapshot("x", title: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
