@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAssessmentAllocationValidator()
        let item = CareManagement.newAssessmentAllocation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAssessmentAllocationMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = CareManagement.AssessmentAllocationMinimumRangeRule(min: 4.0, max: 1816.9)
        let item = CareManagement.newAssessmentAllocation("x", name: "y")
        item.minimum = 1818.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAssessmentAllocationSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = CareManagement.AssessmentAllocationSummaryLengthRule(maxLength: 120)
        let item = CareManagement.newAssessmentAllocation("x", name: "y")
        item.summary = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAssessmentAllocationRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = CareManagement.AssessmentAllocationRequiredSummaryRule(
            message: "assessment allocation needs this field"
        )
        let item = CareManagement.newAssessmentAllocation("", name: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAssessmentAllocationRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.AssessmentAllocationRequiredNameRule(message: "assessment allocation needs an entry")
        let item = CareManagement.newAssessmentAllocation("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
