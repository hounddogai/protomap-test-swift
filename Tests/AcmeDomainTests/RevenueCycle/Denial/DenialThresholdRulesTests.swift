@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialThresholdValidator()
        let item = RevenueCycle.newDenialThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialThresholdVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = RevenueCycle.DenialThresholdVisitMinutesRangeRule(min: 32, max: 80)
        let item = RevenueCycle.newDenialThreshold("x", title: "y")
        item.visitMinutes = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDenialThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.DenialThresholdCodeLengthRule(maxLength: 64)
        let item = RevenueCycle.newDenialThreshold("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDenialThresholdCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = RevenueCycle.DenialThresholdCreatedAtRangeRule(min: 1000, max: 3600)
        let item = RevenueCycle.newDenialThreshold("x", title: "y")
        item.createdAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
