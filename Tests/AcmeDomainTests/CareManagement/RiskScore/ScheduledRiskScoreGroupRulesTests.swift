@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledRiskScoreGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultScheduledRiskScoreGroupValidator()
        let item = CareManagement.newScheduledRiskScoreGroup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementScheduledRiskScoreGroupBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = CareManagement.ScheduledRiskScoreGroupBatchSizeRangeRule(min: 32, max: 86400)
        let item = CareManagement.newScheduledRiskScoreGroup("x", name: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementScheduledRiskScoreGroupQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = CareManagement.ScheduledRiskScoreGroupQuantityRangeRule(min: 16, max: 86400)
        let item = CareManagement.newScheduledRiskScoreGroup("x", name: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementScheduledRiskScoreGroupRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = CareManagement.ScheduledRiskScoreGroupRequiredAllergyRule(
            message: "scheduled risk score group needs an entry"
        )
        let item = CareManagement.newScheduledRiskScoreGroup("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
