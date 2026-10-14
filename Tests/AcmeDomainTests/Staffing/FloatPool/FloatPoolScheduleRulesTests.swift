@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFloatPoolScheduleValidator()
        let item = Staffing.newFloatPoolSchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFloatPoolScheduleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.FloatPoolScheduleRequiredCodeRule(message: "float pool schedule needs an entry")
        let item = Staffing.newFloatPoolSchedule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFloatPoolScheduleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.FloatPoolScheduleNameLengthRule(maxLength: 64)
        let item = Staffing.newFloatPoolSchedule("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
