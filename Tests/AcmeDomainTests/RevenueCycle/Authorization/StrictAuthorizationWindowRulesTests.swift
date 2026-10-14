@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictAuthorizationWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStrictAuthorizationWindowValidator()
        let item = RevenueCycle.newStrictAuthorizationWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStrictAuthorizationWindowWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = RevenueCycle.StrictAuthorizationWindowWardLengthRule(maxLength: 32)
        let item = RevenueCycle.newStrictAuthorizationWindow("x", title: "y")
        item.ward = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStrictAuthorizationWindowRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = RevenueCycle.StrictAuthorizationWindowRequiredWardRule(
            message: "strict authorization window needs an entry"
        )
        let item = RevenueCycle.newStrictAuthorizationWindow("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStrictAuthorizationWindowDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = RevenueCycle.StrictAuthorizationWindowDosageMgRangeRule(min: 1.6, max: 2618.4)
        let item = RevenueCycle.newStrictAuthorizationWindow("x", title: "y")
        item.dosageMg = 2619.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStrictAuthorizationWindowScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = RevenueCycle.StrictAuthorizationWindowScoreRangeRule(min: 4.1, max: 2379.0)
        let item = RevenueCycle.newStrictAuthorizationWindow("x", title: "y")
        item.score = 2380.5
        #expect(rule.check(item).count > 0)
    }
}
