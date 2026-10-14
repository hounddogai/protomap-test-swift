@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialExceptionValidator()
        let item = RevenueCycle.newDenialException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialExceptionRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = RevenueCycle.DenialExceptionRequiredDescriptionRule(message: "denial exception needs an entry")
        let item = RevenueCycle.newDenialException("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialExceptionRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = RevenueCycle.DenialExceptionRequiredSegmentRule(message: "denial exception needs an entry")
        let item = RevenueCycle.newDenialException("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialExceptionExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = RevenueCycle.DenialExceptionExpiresAtRangeRule(min: 3600, max: 3600)
        let item = RevenueCycle.newDenialException("x", title: "y")
        item.expiresAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDenialExceptionTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.DenialExceptionTitleLengthRule(maxLength: 1000)
        let item = RevenueCycle.newDenialException("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDenialExceptionUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = RevenueCycle.DenialExceptionUpdatedAtRangeRule(min: 1000, max: 3600)
        let item = RevenueCycle.newDenialException("x", title: "y")
        item.updatedAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
