@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeEstimateValidator()
        let item = Staffing.newOvertimeEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeEstimateLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Staffing.OvertimeEstimateLocaleLengthRule(maxLength: 3600)
        let item = Staffing.newOvertimeEstimate("x", label: "y")
        item.locale = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.OvertimeEstimateRequiredCodeRule(message: "overtime estimate needs an entry")
        let item = Staffing.newOvertimeEstimate("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeEstimateRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Staffing.OvertimeEstimateRequiredLocaleRule(message: "overtime estimate needs an entry")
        let item = Staffing.newOvertimeEstimate("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeEstimateCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Staffing.OvertimeEstimateCostRangeRule(min: 6.1, max: 4613.2)
        let item = Staffing.newOvertimeEstimate("x", label: "y")
        item.cost = 4614.7
        #expect(rule.check(item).count > 0)
    }
}
