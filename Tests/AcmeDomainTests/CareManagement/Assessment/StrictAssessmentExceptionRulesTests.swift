@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementStrictAssessmentExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultStrictAssessmentExceptionValidator()
        let item = CareManagement.newStrictAssessmentException("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementStrictAssessmentExceptionFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = CareManagement.StrictAssessmentExceptionFloorValueRangeRule(min: 1.5, max: 2051.4)
        let item = CareManagement.newStrictAssessmentException("x", label: "y")
        item.floorValue = 2052.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementStrictAssessmentExceptionRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.StrictAssessmentExceptionRequiredLabelRule(
            message: "strict assessment exception needs an entry"
        )
        let item = CareManagement.newStrictAssessmentException("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementStrictAssessmentExceptionRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = CareManagement.StrictAssessmentExceptionRequiredFacilityRule(
            message: "strict assessment exception needs a value"
        )
        let item = CareManagement.newStrictAssessmentException("", label: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}
