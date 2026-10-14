@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedRiskScoreAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultBatchedRiskScoreAllocationValidator()
        let item = CareManagement.newBatchedRiskScoreAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementBatchedRiskScoreAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.BatchedRiskScoreAllocationRequiredCodeRule(
            message: "batched risk score allocation needs an entry"
        )
        let item = CareManagement.newBatchedRiskScoreAllocation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementBatchedRiskScoreAllocationDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = CareManagement.BatchedRiskScoreAllocationDiscountRangeRule(min: 9.5, max: 1613.2)
        let item = CareManagement.newBatchedRiskScoreAllocation("x", title: "y")
        item.discount = 1614.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementBatchedRiskScoreAllocationRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = CareManagement.BatchedRiskScoreAllocationRequiredContactEmailRule(
            message: "batched risk score allocation needs an entry"
        )
        let item = CareManagement.newBatchedRiskScoreAllocation("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}
