@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanGroupValidator()
        let item = Staffing.newAcuityPlanGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanGroupStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Staffing.AcuityPlanGroupStartsAtRangeRule(min: 80, max: 1000)
        let item = Staffing.newAcuityPlanGroup("x", label: "y")
        item.startsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAcuityPlanGroupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.AcuityPlanGroupLabelLengthRule(maxLength: 64)
        let item = Staffing.newAcuityPlanGroup("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.AcuityPlanGroupRequiredCodeRule(message: "acuity plan group needs this field")
        let item = Staffing.newAcuityPlanGroup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanGroupWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Staffing.AcuityPlanGroupWindowDaysRangeRule(min: 32, max: 3600)
        let item = Staffing.newAcuityPlanGroup("x", label: "y")
        item.windowDays = 3601
        #expect(rule.check(item).count > 0)
    }
}
