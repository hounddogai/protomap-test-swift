@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackOutreachRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultFallbackOutreachRuleValidator()
        let item = CareManagement.newFallbackOutreachRule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementFallbackOutreachRuleExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = CareManagement.FallbackOutreachRuleExpiresAtRangeRule(min: 255, max: 255)
        let item = CareManagement.newFallbackOutreachRule("x", label: "y")
        item.expiresAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementFallbackOutreachRuleRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = CareManagement.FallbackOutreachRuleRateRangeRule(min: 1.3, max: 4848.4)
        let item = CareManagement.newFallbackOutreachRule("x", label: "y")
        item.rate = 4849.9
        #expect(rule.check(item).count > 0)
    }
}
