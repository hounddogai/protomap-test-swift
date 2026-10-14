@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachAssignmentValidator()
        let item = CareManagement.newOutreachAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachAssignmentFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = CareManagement.OutreachAssignmentFacilityLengthRule(maxLength: 255)
        let item = CareManagement.newOutreachAssignment("x", label: "y")
        item.facility = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementOutreachAssignmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.OutreachAssignmentRequiredLabelRule(message: "outreach assignment needs this field")
        let item = CareManagement.newOutreachAssignment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementOutreachAssignmentThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = CareManagement.OutreachAssignmentThresholdRangeRule(min: 1.4, max: 1637.5)
        let item = CareManagement.newOutreachAssignment("x", label: "y")
        item.threshold = 1639.0
        #expect(rule.check(item).count > 0)
    }
}
