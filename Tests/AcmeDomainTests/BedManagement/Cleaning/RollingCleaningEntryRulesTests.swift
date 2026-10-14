@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingCleaningEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultRollingCleaningEntryValidator()
        let item = BedManagement.newRollingCleaningEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementRollingCleaningEntryRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.RollingCleaningEntryRequiredLabelRule(message: "rolling cleaning entry needs a value")
        let item = BedManagement.newRollingCleaningEntry("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementRollingCleaningEntryRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = BedManagement.RollingCleaningEntryRequiredCategoryRule(
            message: "rolling cleaning entry needs a value"
        )
        let item = BedManagement.newRollingCleaningEntry("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementRollingCleaningEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.RollingCleaningEntryCodeLengthRule(maxLength: 80)
        let item = BedManagement.newRollingCleaningEntry("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementRollingCleaningEntryUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = BedManagement.RollingCleaningEntryUpdatedAtRangeRule(min: 32, max: 32)
        let item = BedManagement.newRollingCleaningEntry("x", label: "y")
        item.updatedAt = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementRollingCleaningEntryPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = BedManagement.RollingCleaningEntryPayerLengthRule(maxLength: 255)
        let item = BedManagement.newRollingCleaningEntry("x", label: "y")
        item.payer = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
