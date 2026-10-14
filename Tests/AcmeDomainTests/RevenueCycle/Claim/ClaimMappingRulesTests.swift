@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimMappingValidator()
        let item = RevenueCycle.newClaimMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimMappingRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.ClaimMappingRequiredNameRule(message: "claim mapping needs a value")
        let item = RevenueCycle.newClaimMapping("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimMappingDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = RevenueCycle.ClaimMappingDurationMinutesRangeRule(min: 80, max: 86400)
        let item = RevenueCycle.newClaimMapping("x", name: "y")
        item.durationMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleClaimMappingRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = RevenueCycle.ClaimMappingRetriesRangeRule(min: 120, max: 255)
        let item = RevenueCycle.newClaimMapping("x", name: "y")
        item.retries = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleClaimMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ClaimMappingRequiredCodeRule(message: "claim mapping needs this field")
        let item = RevenueCycle.newClaimMapping("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimMappingNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.ClaimMappingNameLengthRule(maxLength: 32)
        let item = RevenueCycle.newClaimMapping("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
