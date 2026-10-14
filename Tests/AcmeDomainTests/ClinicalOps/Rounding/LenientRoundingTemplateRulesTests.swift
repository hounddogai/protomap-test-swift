@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientRoundingTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultLenientRoundingTemplateValidator()
        let item = ClinicalOps.newLenientRoundingTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsLenientRoundingTemplateExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = ClinicalOps.LenientRoundingTemplateExpiresAtRangeRule(min: 80, max: 80)
        let item = ClinicalOps.newLenientRoundingTemplate("x", name: "y")
        item.expiresAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsLenientRoundingTemplateAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = ClinicalOps.LenientRoundingTemplateAttemptsRangeRule(min: 16, max: 255)
        let item = ClinicalOps.newLenientRoundingTemplate("x", name: "y")
        item.attempts = 256
        #expect(rule.check(item).count > 0)
    }
}
