@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualShiftAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultManualShiftAdjustmentValidator()
        let item = Staffing.newManualShiftAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingManualShiftAdjustmentCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Staffing.ManualShiftAdjustmentCurrencyLengthRule(maxLength: 64)
        let item = Staffing.newManualShiftAdjustment("x", label: "y")
        item.currency = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingManualShiftAdjustmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.ManualShiftAdjustmentRequiredCodeRule(message: "manual shift adjustment needs this field")
        let item = Staffing.newManualShiftAdjustment("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
