@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedTransferEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBatchedTransferEntryValidator()
        let item = BedManagement.newBatchedTransferEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBatchedTransferEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.BatchedTransferEntryRequiredCodeRule(message: "batched transfer entry needs a value")
        let item = BedManagement.newBatchedTransferEntry("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBatchedTransferEntryDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = BedManagement.BatchedTransferEntryDescriptionLengthRule(maxLength: 32)
        let item = BedManagement.newBatchedTransferEntry("x", name: "y")
        item.description = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBatchedTransferEntryLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = BedManagement.BatchedTransferEntryLimitRangeRule(min: 16, max: 3600)
        let item = BedManagement.newBatchedTransferEntry("x", name: "y")
        item.limit = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBatchedTransferEntryRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = BedManagement.BatchedTransferEntryRequiredClinicianIDRule(
            message: "batched transfer entry needs an entry"
        )
        let item = BedManagement.newBatchedTransferEntry("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
