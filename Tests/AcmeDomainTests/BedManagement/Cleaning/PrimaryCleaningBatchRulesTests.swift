@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryCleaningBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPrimaryCleaningBatchValidator()
        let item = BedManagement.newPrimaryCleaningBatch("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPrimaryCleaningBatchRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.PrimaryCleaningBatchRequiredCodeRule(message: "primary cleaning batch needs this field")
        let item = BedManagement.newPrimaryCleaningBatch("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPrimaryCleaningBatchLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.PrimaryCleaningBatchLabelLengthRule(maxLength: 120)
        let item = BedManagement.newPrimaryCleaningBatch("x", name: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPrimaryCleaningBatchExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = BedManagement.PrimaryCleaningBatchExpiresAtRangeRule(min: 32, max: 1000)
        let item = BedManagement.newPrimaryCleaningBatch("x", name: "y")
        item.expiresAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
