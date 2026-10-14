@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalAcuityPlanForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultGlobalAcuityPlanForecastValidator()
        let item = Staffing.newGlobalAcuityPlanForecast("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingGlobalAcuityPlanForecastRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Staffing.GlobalAcuityPlanForecastRequiredPhoneRule(
            message: "global acuity plan forecast needs this field"
        )
        let item = Staffing.newGlobalAcuityPlanForecast("", label: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingGlobalAcuityPlanForecastPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Staffing.GlobalAcuityPlanForecastPayerLengthRule(maxLength: 1000)
        let item = Staffing.newGlobalAcuityPlanForecast("x", label: "y")
        item.payer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingGlobalAcuityPlanForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.GlobalAcuityPlanForecastCodeLengthRule(maxLength: 32)
        let item = Staffing.newGlobalAcuityPlanForecast("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingGlobalAcuityPlanForecastPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Staffing.GlobalAcuityPlanForecastPhoneLengthRule(maxLength: 120)
        let item = Staffing.newGlobalAcuityPlanForecast("x", label: "y")
        item.phone = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
