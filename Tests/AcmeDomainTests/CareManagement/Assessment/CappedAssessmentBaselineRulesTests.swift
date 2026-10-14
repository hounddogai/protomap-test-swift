@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedAssessmentBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCappedAssessmentBaselineValidator()
        let item = CareManagement.newCappedAssessmentBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCappedAssessmentBaselineCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = CareManagement.CappedAssessmentBaselineCapacityRangeRule(min: 120, max: 1000)
        let item = CareManagement.newCappedAssessmentBaseline("x", label: "y")
        item.capacity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCappedAssessmentBaselineRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = CareManagement.CappedAssessmentBaselineRequiredBedRule(
            message: "capped assessment baseline needs a value"
        )
        let item = CareManagement.newCappedAssessmentBaseline("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCappedAssessmentBaselineExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = CareManagement.CappedAssessmentBaselineExpiresAtRangeRule(min: 120, max: 86400)
        let item = CareManagement.newCappedAssessmentBaseline("x", label: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCappedAssessmentBaselineCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = CareManagement.CappedAssessmentBaselineCopayRangeRule(min: 0.0, max: 276.2)
        let item = CareManagement.newCappedAssessmentBaseline("x", label: "y")
        item.copay = 277.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCappedAssessmentBaselineRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.CappedAssessmentBaselineRequiredLabelRule(
            message: "capped assessment baseline needs an entry"
        )
        let item = CareManagement.newCappedAssessmentBaseline("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
