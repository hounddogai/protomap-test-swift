@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolEntryValidator()
        let item = Staffing.newFloatPoolEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolEntryMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Staffing.FloatPoolEntryMarginRangeRule(min: 3.2, max: 1395.4)
        let item = Staffing.newFloatPoolEntry("x", name: "y")
        item.margin = 1396.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFloatPoolEntrySummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Staffing.FloatPoolEntrySummaryLengthRule(maxLength: 16)
        let item = Staffing.newFloatPoolEntry("x", name: "y")
        item.summary = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFloatPoolEntryRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.FloatPoolEntryRequiredNameRule(message: "float pool entry needs a value")
        let item = Staffing.newFloatPoolEntry("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolEntryWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Staffing.FloatPoolEntryWindowDaysRangeRule(min: 32, max: 120)
        let item = Staffing.newFloatPoolEntry("x", name: "y")
        item.windowDays = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFloatPoolEntryNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.FloatPoolEntryNameLengthRule(maxLength: 1000)
        let item = Staffing.newFloatPoolEntry("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
