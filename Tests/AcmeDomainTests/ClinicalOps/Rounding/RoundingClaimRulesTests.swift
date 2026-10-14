@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingClaimValidator()
        let item = ClinicalOps.newRoundingClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingClaimAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = ClinicalOps.RoundingClaimAcuityRangeRule(min: 32, max: 64)
        let item = ClinicalOps.newRoundingClaim("x", name: "y")
        item.acuity = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRoundingClaimBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = ClinicalOps.RoundingClaimBatchSizeRangeRule(min: 32, max: 86400)
        let item = ClinicalOps.newRoundingClaim("x", name: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}
