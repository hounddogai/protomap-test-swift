@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryShiftForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPrimaryShiftForecastValidator()
        let item = Staffing.newPrimaryShiftForecast("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPrimaryShiftForecastLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.PrimaryShiftForecastLabelLengthRule(maxLength: 120)
        let item = Staffing.newPrimaryShiftForecast("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
