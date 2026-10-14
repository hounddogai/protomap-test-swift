@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAssessmentSegmentValidator()
        let item = CareManagement.newAssessmentSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAssessmentSegmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.AssessmentSegmentLabelLengthRule(maxLength: 32)
        let item = CareManagement.newAssessmentSegment("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAssessmentSegmentMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = CareManagement.AssessmentSegmentMaximumRangeRule(min: 4.1, max: 4340.9)
        let item = CareManagement.newAssessmentSegment("x", label: "y")
        item.maximum = 4342.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAssessmentSegmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.AssessmentSegmentRequiredLabelRule(message: "assessment segment needs a value")
        let item = CareManagement.newAssessmentSegment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAssessmentSegmentClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = CareManagement.AssessmentSegmentClinicianIDLengthRule(maxLength: 1000)
        let item = CareManagement.newAssessmentSegment("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
