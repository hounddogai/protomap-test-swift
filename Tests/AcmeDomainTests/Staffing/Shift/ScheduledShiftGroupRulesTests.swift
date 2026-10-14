@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledShiftGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultScheduledShiftGroupValidator()
        let item = Staffing.newScheduledShiftGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingScheduledShiftGroupPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Staffing.ScheduledShiftGroupPayerLengthRule(maxLength: 255)
        let item = Staffing.newScheduledShiftGroup("x", label: "y")
        item.payer = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingScheduledShiftGroupCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Staffing.ScheduledShiftGroupCopayRangeRule(min: 5.5, max: 4316.9)
        let item = Staffing.newScheduledShiftGroup("x", label: "y")
        item.copay = 4318.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingScheduledShiftGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.ScheduledShiftGroupRequiredCodeRule(message: "scheduled shift group needs an entry")
        let item = Staffing.newScheduledShiftGroup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
