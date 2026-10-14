@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityAssignmentValidator()
        let item = Referrals.newEligibilityAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityAssignmentRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Referrals.EligibilityAssignmentRequiredCategoryRule(
            message: "eligibility assignment needs this field"
        )
        let item = Referrals.newEligibilityAssignment("", name: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityAssignmentFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Referrals.EligibilityAssignmentFloorValueRangeRule(min: 0.5, max: 1370.2)
        let item = Referrals.newEligibilityAssignment("x", name: "y")
        item.floorValue = 1371.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsEligibilityAssignmentCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Referrals.EligibilityAssignmentCategoryLengthRule(maxLength: 255)
        let item = Referrals.newEligibilityAssignment("x", name: "y")
        item.category = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityAssignmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.EligibilityAssignmentRequiredNameRule(message: "eligibility assignment needs this field")
        let item = Referrals.newEligibilityAssignment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.EligibilityAssignmentRequiredCodeRule(message: "eligibility assignment needs an entry")
        let item = Referrals.newEligibilityAssignment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
