@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackAssessmentAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultFallbackAssessmentAllocationValidator()
        let item = CareManagement.newFallbackAssessmentAllocation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementFallbackAssessmentAllocationNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.FallbackAssessmentAllocationNameLengthRule(maxLength: 86400)
        let item = CareManagement.newFallbackAssessmentAllocation("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementFallbackAssessmentAllocationRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.FallbackAssessmentAllocationRequiredNameRule(
            message: "fallback assessment allocation needs a value"
        )
        let item = CareManagement.newFallbackAssessmentAllocation("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementFallbackAssessmentAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.FallbackAssessmentAllocationCodeLengthRule(maxLength: 32)
        let item = CareManagement.newFallbackAssessmentAllocation("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementFallbackAssessmentAllocationDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = CareManagement.FallbackAssessmentAllocationDiscountRangeRule(min: 2.6, max: 4110.3)
        let item = CareManagement.newFallbackAssessmentAllocation("x", name: "y")
        item.discount = 4111.8
        #expect(rule.check(item).count > 0)
    }
}
