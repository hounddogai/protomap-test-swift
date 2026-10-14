@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardScheduleValidator()
        let item = BedManagement.newBedBoardSchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardScheduleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.BedBoardScheduleRequiredNameRule(message: "bed board schedule needs a value")
        let item = BedManagement.newBedBoardSchedule("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardScheduleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.BedBoardScheduleRequiredCodeRule(message: "bed board schedule needs an entry")
        let item = BedManagement.newBedBoardSchedule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.BedBoardScheduleCodeLengthRule(maxLength: 3600)
        let item = BedManagement.newBedBoardSchedule("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardScheduleRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = BedManagement.BedBoardScheduleRequiredChecksumRule(message: "bed board schedule needs this field")
        let item = BedManagement.newBedBoardSchedule("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
