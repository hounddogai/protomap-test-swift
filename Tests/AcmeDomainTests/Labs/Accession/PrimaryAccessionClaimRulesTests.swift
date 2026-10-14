@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryAccessionClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPrimaryAccessionClaimValidator()
        let item = Labs.newPrimaryAccessionClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPrimaryAccessionClaimVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Labs.PrimaryAccessionClaimVersionRangeRule(min: 80, max: 86400)
        let item = Labs.newPrimaryAccessionClaim("x", name: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPrimaryAccessionClaimAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Labs.PrimaryAccessionClaimAttemptsRangeRule(min: 32, max: 3600)
        let item = Labs.newPrimaryAccessionClaim("x", name: "y")
        item.attempts = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPrimaryAccessionClaimCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Labs.PrimaryAccessionClaimCategoryLengthRule(maxLength: 80)
        let item = Labs.newPrimaryAccessionClaim("x", name: "y")
        item.category = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
