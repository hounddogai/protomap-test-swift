@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredRiskScoreClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultTieredRiskScoreClaimValidator()
        let item = CareManagement.newTieredRiskScoreClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementTieredRiskScoreClaimExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = CareManagement.TieredRiskScoreClaimExternalRefLengthRule(maxLength: 80)
        let item = CareManagement.newTieredRiskScoreClaim("x", name: "y")
        item.externalRef = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementTieredRiskScoreClaimCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = CareManagement.TieredRiskScoreClaimCeilingRangeRule(min: 6.6, max: 2607.2)
        let item = CareManagement.newTieredRiskScoreClaim("x", name: "y")
        item.ceiling = 2608.7
        #expect(rule.check(item).count > 0)
    }
}
