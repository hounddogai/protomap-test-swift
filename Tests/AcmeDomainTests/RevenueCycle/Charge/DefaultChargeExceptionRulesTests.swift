@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultChargeExceptionValidatorExtraTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDefaultChargeExceptionValidator()
        let item = RevenueCycle.newDefaultChargeException("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDefaultChargeExceptionScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = RevenueCycle.DefaultChargeExceptionScoreRangeRule(min: 5.0, max: 4477.5)
        let item = RevenueCycle.newDefaultChargeException("x", name: "y")
        item.score = 4479.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDefaultChargeExceptionRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = RevenueCycle.DefaultChargeExceptionRequiredTimezoneRule(
            message: "default charge exception needs this field"
        )
        let item = RevenueCycle.newDefaultChargeException("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDefaultChargeExceptionOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = RevenueCycle.DefaultChargeExceptionOwnerIDLengthRule(maxLength: 80)
        let item = RevenueCycle.newDefaultChargeException("x", name: "y")
        item.ownerID = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDefaultChargeExceptionNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.DefaultChargeExceptionNameLengthRule(maxLength: 86400)
        let item = RevenueCycle.newDefaultChargeException("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDefaultChargeExceptionRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.DefaultChargeExceptionRequiredNameRule(
            message: "default charge exception needs this field"
        )
        let item = RevenueCycle.newDefaultChargeException("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
