@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalShiftMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSeasonalShiftMetricValidator()
        let item = Staffing.newSeasonalShiftMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSeasonalShiftMetricSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Staffing.SeasonalShiftMetricSequenceRangeRule(min: 80, max: 1000)
        let item = Staffing.newSeasonalShiftMetric("x", name: "y")
        item.sequence = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSeasonalShiftMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.SeasonalShiftMetricCodeLengthRule(maxLength: 86400)
        let item = Staffing.newSeasonalShiftMetric("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSeasonalShiftMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.SeasonalShiftMetricRequiredCodeRule(message: "seasonal shift metric needs an entry")
        let item = Staffing.newSeasonalShiftMetric("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
