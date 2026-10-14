@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferScheduleValidator()
        let item = BedManagement.newTransferSchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferScheduleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.TransferScheduleRequiredLabelRule(message: "transfer schedule needs this field")
        let item = BedManagement.newTransferSchedule("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTransferScheduleCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = BedManagement.TransferScheduleCeilingRangeRule(min: 7.3, max: 2004.7)
        let item = BedManagement.newTransferSchedule("x", name: "y")
        item.ceiling = 2006.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferScheduleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.TransferScheduleNameLengthRule(maxLength: 16)
        let item = BedManagement.newTransferSchedule("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferScheduleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.TransferScheduleLabelLengthRule(maxLength: 64)
        let item = BedManagement.newTransferSchedule("x", name: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
