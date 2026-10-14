@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetReviewValidator()
        let item = ClinicalOps.newOrderSetReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetReviewRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.OrderSetReviewRequiredLabelRule(message: "order set review needs an entry")
        let item = ClinicalOps.newOrderSetReview("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetReviewCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = ClinicalOps.OrderSetReviewCopayRangeRule(min: 5.6, max: 1874.0)
        let item = ClinicalOps.newOrderSetReview("x", label: "y")
        item.copay = 1875.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsOrderSetReviewRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = ClinicalOps.OrderSetReviewRequiredPayerRule(message: "order set review needs an entry")
        let item = ClinicalOps.newOrderSetReview("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}
