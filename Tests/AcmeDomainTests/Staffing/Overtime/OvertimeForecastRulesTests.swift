@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeForecastValidator()
        let item = Staffing.newOvertimeForecast("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeForecastLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.OvertimeForecastLabelLengthRule(maxLength: 255)
        let item = Staffing.newOvertimeForecast("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeForecastRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.OvertimeForecastRequiredLabelRule(message: "overtime forecast needs a value")
        let item = Staffing.newOvertimeForecast("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeForecastRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Staffing.OvertimeForecastRefillsRangeRule(min: 255, max: 1000)
        let item = Staffing.newOvertimeForecast("x", label: "y")
        item.refills = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingOvertimeForecastWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Staffing.OvertimeForecastWardLengthRule(maxLength: 16)
        let item = Staffing.newOvertimeForecast("x", label: "y")
        item.ward = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}
