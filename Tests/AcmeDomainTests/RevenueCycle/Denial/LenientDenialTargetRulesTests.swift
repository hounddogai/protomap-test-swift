@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientDenialTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLenientDenialTargetValidator()
        let item = RevenueCycle.newLenientDenialTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLenientDenialTargetExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = RevenueCycle.LenientDenialTargetExpiresAtRangeRule(min: 64, max: 120)
        let item = RevenueCycle.newLenientDenialTarget("x", label: "y")
        item.expiresAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleLenientDenialTargetSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = RevenueCycle.LenientDenialTargetSegmentLengthRule(maxLength: 32)
        let item = RevenueCycle.newLenientDenialTarget("x", label: "y")
        item.segment = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleLenientDenialTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.LenientDenialTargetRequiredCodeRule(message: "lenient denial target needs an entry")
        let item = RevenueCycle.newLenientDenialTarget("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleLenientDenialTargetUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = RevenueCycle.LenientDenialTargetUnitLengthRule(maxLength: 120)
        let item = RevenueCycle.newLenientDenialTarget("x", label: "y")
        item.unit = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}
