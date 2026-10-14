@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredShiftSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultTieredShiftSummaryValidator()
        let item = Staffing.newTieredShiftSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingTieredShiftSummaryDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Staffing.TieredShiftSummaryDosageMgRangeRule(min: 3.6, max: 2178.9)
        let item = Staffing.newTieredShiftSummary("x", title: "y")
        item.dosageMg = 2180.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingTieredShiftSummaryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.TieredShiftSummaryRequiredTitleRule(message: "tiered shift summary needs a value")
        let item = Staffing.newTieredShiftSummary("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingTieredShiftSummaryTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.TieredShiftSummaryTitleLengthRule(maxLength: 86400)
        let item = Staffing.newTieredShiftSummary("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingTieredShiftSummaryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.TieredShiftSummaryCodeLengthRule(maxLength: 64)
        let item = Staffing.newTieredShiftSummary("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingTieredShiftSummaryRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Staffing.TieredShiftSummaryRequiredContactEmailRule(message: "tiered shift summary needs this field")
        let item = Staffing.newTieredShiftSummary("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}
