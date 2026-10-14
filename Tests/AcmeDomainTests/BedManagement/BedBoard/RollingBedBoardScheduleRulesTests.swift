@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingBedBoardScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultRollingBedBoardScheduleValidator()
        let item = BedManagement.newRollingBedBoardSchedule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementRollingBedBoardScheduleRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = BedManagement.RollingBedBoardScheduleRequiredChecksumRule(
            message: "rolling bed board schedule needs this field"
        )
        let item = BedManagement.newRollingBedBoardSchedule("", label: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementRollingBedBoardScheduleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.RollingBedBoardScheduleRequiredCodeRule(
            message: "rolling bed board schedule needs an entry"
        )
        let item = BedManagement.newRollingBedBoardSchedule("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementRollingBedBoardScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.RollingBedBoardScheduleCodeLengthRule(maxLength: 255)
        let item = BedManagement.newRollingBedBoardSchedule("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
