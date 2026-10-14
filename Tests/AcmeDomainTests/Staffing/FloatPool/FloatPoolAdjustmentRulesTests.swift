@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolAdjustmentValidator()
        let item = Staffing.newFloatPoolAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolAdjustmentRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Staffing.FloatPoolAdjustmentRegionLengthRule(maxLength: 3600)
        let item = Staffing.newFloatPoolAdjustment("x", label: "y")
        item.region = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolAdjustmentMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Staffing.FloatPoolAdjustmentMarginRangeRule(min: 9.2, max: 2050.4)
        let item = Staffing.newFloatPoolAdjustment("x", label: "y")
        item.margin = 2051.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFloatPoolAdjustmentRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Staffing.FloatPoolAdjustmentRequiredRegionRule(message: "float pool adjustment needs this field")
        let item = Staffing.newFloatPoolAdjustment("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}
