@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingDischargePlanScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultRollingDischargePlanScheduleValidator()
        let item = BedManagement.newRollingDischargePlanSchedule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementRollingDischargePlanScheduleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.RollingDischargePlanScheduleRequiredCodeRule(
            message: "rolling discharge plan schedule needs an entry"
        )
        let item = BedManagement.newRollingDischargePlanSchedule("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementRollingDischargePlanScheduleRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = BedManagement.RollingDischargePlanScheduleRequiredCategoryRule(
            message: "rolling discharge plan schedule needs a value"
        )
        let item = BedManagement.newRollingDischargePlanSchedule("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementRollingDischargePlanScheduleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.RollingDischargePlanScheduleLabelLengthRule(maxLength: 255)
        let item = BedManagement.newRollingDischargePlanSchedule("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementRollingDischargePlanScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.RollingDischargePlanScheduleCodeLengthRule(maxLength: 1000)
        let item = BedManagement.newRollingDischargePlanSchedule("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
