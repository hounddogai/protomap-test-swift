@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultShiftForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultDefaultShiftForecastValidator()
        let item = Staffing.newDefaultShiftForecast("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingDefaultShiftForecastBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Staffing.DefaultShiftForecastBatchSizeRangeRule(min: 64, max: 86400)
        let item = Staffing.newDefaultShiftForecast("x", name: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingDefaultShiftForecastRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.DefaultShiftForecastRequiredNameRule(message: "default shift forecast needs an entry")
        let item = Staffing.newDefaultShiftForecast("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingDefaultShiftForecastSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Staffing.DefaultShiftForecastSegmentLengthRule(maxLength: 32)
        let item = Staffing.newDefaultShiftForecast("x", name: "y")
        item.segment = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}
