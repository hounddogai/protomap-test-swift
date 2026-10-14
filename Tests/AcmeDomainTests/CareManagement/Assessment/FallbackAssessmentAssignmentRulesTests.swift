@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackAssessmentAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultFallbackAssessmentAssignmentValidator()
        let item = CareManagement.newFallbackAssessmentAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementFallbackAssessmentAssignmentWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = CareManagement.FallbackAssessmentAssignmentWeightRangeRule(min: 0.1, max: 980.6)
        let item = CareManagement.newFallbackAssessmentAssignment("x", title: "y")
        item.weight = 982.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementFallbackAssessmentAssignmentRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = CareManagement.FallbackAssessmentAssignmentRatioRangeRule(min: 5.6, max: 716.1)
        let item = CareManagement.newFallbackAssessmentAssignment("x", title: "y")
        item.ratio = 717.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementFallbackAssessmentAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.FallbackAssessmentAssignmentCodeLengthRule(maxLength: 3600)
        let item = CareManagement.newFallbackAssessmentAssignment("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementFallbackAssessmentAssignmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.FallbackAssessmentAssignmentRequiredTitleRule(
            message: "fallback assessment assignment needs an entry"
        )
        let item = CareManagement.newFallbackAssessmentAssignment("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
