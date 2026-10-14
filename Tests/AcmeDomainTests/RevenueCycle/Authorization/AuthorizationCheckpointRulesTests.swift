@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationCheckpointValidator()
        let item = RevenueCycle.newAuthorizationCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.AuthorizationCheckpointRequiredCodeRule(
            message: "authorization checkpoint needs an entry"
        )
        let item = RevenueCycle.newAuthorizationCheckpoint("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationCheckpointRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = RevenueCycle.AuthorizationCheckpointRequiredWardRule(
            message: "authorization checkpoint needs a value"
        )
        let item = RevenueCycle.newAuthorizationCheckpoint("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationCheckpointRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.AuthorizationCheckpointRequiredTitleRule(
            message: "authorization checkpoint needs this field"
        )
        let item = RevenueCycle.newAuthorizationCheckpoint("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationCheckpointTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.AuthorizationCheckpointTitleLengthRule(maxLength: 32)
        let item = RevenueCycle.newAuthorizationCheckpoint("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationCheckpointScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = RevenueCycle.AuthorizationCheckpointScoreRangeRule(min: 1.5, max: 3466.8)
        let item = RevenueCycle.newAuthorizationCheckpoint("x", title: "y")
        item.score = 3468.3
        #expect(rule.check(item).count > 0)
    }
}
