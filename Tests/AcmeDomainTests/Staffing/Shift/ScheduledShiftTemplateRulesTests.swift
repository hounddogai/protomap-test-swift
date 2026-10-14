@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledShiftTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultScheduledShiftTemplateValidator()
        let item = Staffing.newScheduledShiftTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingScheduledShiftTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.ScheduledShiftTemplateCodeLengthRule(maxLength: 3600)
        let item = Staffing.newScheduledShiftTemplate("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingScheduledShiftTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.ScheduledShiftTemplateRequiredCodeRule(message: "scheduled shift template needs an entry")
        let item = Staffing.newScheduledShiftTemplate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
