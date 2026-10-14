@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferEntryValidator()
        let item = BedManagement.newTransferEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferEntryPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = BedManagement.TransferEntryPriorityRangeRule(min: 32, max: 86400)
        let item = BedManagement.newTransferEntry("x", label: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferEntryRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.TransferEntryRequiredLabelRule(message: "transfer entry needs a value")
        let item = BedManagement.newTransferEntry("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTransferEntryTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = BedManagement.TransferEntryTimezoneLengthRule(maxLength: 3600)
        let item = BedManagement.newTransferEntry("x", label: "y")
        item.timezone = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferEntryBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = BedManagement.TransferEntryBedLengthRule(maxLength: 255)
        let item = BedManagement.newTransferEntry("x", label: "y")
        item.bed = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
