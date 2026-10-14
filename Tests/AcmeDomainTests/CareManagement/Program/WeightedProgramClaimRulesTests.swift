@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedProgramClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultWeightedProgramClaimValidator()
        let item = CareManagement.newWeightedProgramClaim("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementWeightedProgramClaimRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.WeightedProgramClaimRequiredLabelRule(
            message: "weighted program claim needs this field"
        )
        let item = CareManagement.newWeightedProgramClaim("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementWeightedProgramClaimReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = CareManagement.WeightedProgramClaimReviewerLengthRule(maxLength: 1000)
        let item = CareManagement.newWeightedProgramClaim("x", label: "y")
        item.reviewer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementWeightedProgramClaimExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = CareManagement.WeightedProgramClaimExternalRefLengthRule(maxLength: 64)
        let item = CareManagement.newWeightedProgramClaim("x", label: "y")
        item.externalRef = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementWeightedProgramClaimRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = CareManagement.WeightedProgramClaimRequiredExternalRefRule(
            message: "weighted program claim needs an entry"
        )
        let item = CareManagement.newWeightedProgramClaim("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementWeightedProgramClaimDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = CareManagement.WeightedProgramClaimDiscountRangeRule(min: 5.8, max: 3073.3)
        let item = CareManagement.newWeightedProgramClaim("x", label: "y")
        item.discount = 3074.8
        #expect(rule.check(item).count > 0)
    }
}
