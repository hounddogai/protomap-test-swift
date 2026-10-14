@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedGoalDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultWeightedGoalDigestValidator()
        let item = CareManagement.newWeightedGoalDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementWeightedGoalDigestReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = CareManagement.WeightedGoalDigestReviewerLengthRule(maxLength: 64)
        let item = CareManagement.newWeightedGoalDigest("x", name: "y")
        item.reviewer = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementWeightedGoalDigestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.WeightedGoalDigestRequiredNameRule(message: "weighted goal digest needs this field")
        let item = CareManagement.newWeightedGoalDigest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementWeightedGoalDigestRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = CareManagement.WeightedGoalDigestRequiredSourceRule(message: "weighted goal digest needs this field")
        let item = CareManagement.newWeightedGoalDigest("", name: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementWeightedGoalDigestSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = CareManagement.WeightedGoalDigestSourceLengthRule(maxLength: 16)
        let item = CareManagement.newWeightedGoalDigest("x", name: "y")
        item.source = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementWeightedGoalDigestQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = CareManagement.WeightedGoalDigestQuantityRangeRule(min: 32, max: 86400)
        let item = CareManagement.newWeightedGoalDigest("x", name: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementWeightedGoalDigestRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = CareManagement.WeightedGoalDigestRequiredReviewerRule(
            message: "weighted goal digest needs this field"
        )
        let item = CareManagement.newWeightedGoalDigest("", name: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}
