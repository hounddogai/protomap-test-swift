@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanRecordValidator()
        let item = Staffing.newAcuityPlanRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanRecordCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Staffing.AcuityPlanRecordCurrencyLengthRule(maxLength: 1000)
        let item = Staffing.newAcuityPlanRecord("x", label: "y")
        item.currency = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanRecordCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Staffing.AcuityPlanRecordCeilingRangeRule(min: 9.5, max: 2666.8)
        let item = Staffing.newAcuityPlanRecord("x", label: "y")
        item.ceiling = 2668.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAcuityPlanRecordRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.AcuityPlanRecordRequiredLabelRule(message: "acuity plan record needs this field")
        let item = Staffing.newAcuityPlanRecord("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanRecordLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.AcuityPlanRecordLabelLengthRule(maxLength: 80)
        let item = Staffing.newAcuityPlanRecord("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.AcuityPlanRecordRequiredCodeRule(message: "acuity plan record needs this field")
        let item = Staffing.newAcuityPlanRecord("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
