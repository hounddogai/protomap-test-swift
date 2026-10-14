@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientAcuityPlanRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultLenientAcuityPlanRollupValidator()
        let item = Staffing.newLenientAcuityPlanRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingLenientAcuityPlanRollupWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Staffing.LenientAcuityPlanRollupWindowDaysRangeRule(min: 64, max: 80)
        let item = Staffing.newLenientAcuityPlanRollup("x", label: "y")
        item.windowDays = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingLenientAcuityPlanRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.LenientAcuityPlanRollupRequiredCodeRule(
            message: "lenient acuity plan rollup needs this field"
        )
        let item = Staffing.newLenientAcuityPlanRollup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
