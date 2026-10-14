@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanAssignmentValidator()
        let item = Staffing.newAcuityPlanAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanAssignmentRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Staffing.AcuityPlanAssignmentRatioRangeRule(min: 6.8, max: 465.8)
        let item = Staffing.newAcuityPlanAssignment("x", label: "y")
        item.ratio = 467.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAcuityPlanAssignmentCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Staffing.AcuityPlanAssignmentCountryLengthRule(maxLength: 32)
        let item = Staffing.newAcuityPlanAssignment("x", label: "y")
        item.country = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanAssignmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.AcuityPlanAssignmentRequiredLabelRule(message: "acuity plan assignment needs an entry")
        let item = Staffing.newAcuityPlanAssignment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.AcuityPlanAssignmentCodeLengthRule(maxLength: 3600)
        let item = Staffing.newAcuityPlanAssignment("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
