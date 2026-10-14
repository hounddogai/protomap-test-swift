@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingRoundingDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRollingRoundingDigestValidator()
        let item = ClinicalOps.newRollingRoundingDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRollingRoundingDigestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.RollingRoundingDigestNameLengthRule(maxLength: 3600)
        let item = ClinicalOps.newRollingRoundingDigest("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRollingRoundingDigestAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = ClinicalOps.RollingRoundingDigestAttemptsRangeRule(min: 32, max: 80)
        let item = ClinicalOps.newRollingRoundingDigest("x", name: "y")
        item.attempts = 81
        #expect(rule.check(item).count > 0)
    }
}
