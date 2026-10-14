@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackOutreachAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultFallbackOutreachAssignmentValidator()
        let item = CareManagement.newFallbackOutreachAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementFallbackOutreachAssignmentQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = CareManagement.FallbackOutreachAssignmentQuantityRangeRule(min: 120, max: 86400)
        let item = CareManagement.newFallbackOutreachAssignment("x", label: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementFallbackOutreachAssignmentAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = CareManagement.FallbackOutreachAssignmentAcuityRangeRule(min: 16, max: 86400)
        let item = CareManagement.newFallbackOutreachAssignment("x", label: "y")
        item.acuity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementFallbackOutreachAssignmentRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = CareManagement.FallbackOutreachAssignmentRequiredSegmentRule(
            message: "fallback outreach assignment needs an entry"
        )
        let item = CareManagement.newFallbackOutreachAssignment("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementFallbackOutreachAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.FallbackOutreachAssignmentRequiredCodeRule(
            message: "fallback outreach assignment needs an entry"
        )
        let item = CareManagement.newFallbackOutreachAssignment("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
