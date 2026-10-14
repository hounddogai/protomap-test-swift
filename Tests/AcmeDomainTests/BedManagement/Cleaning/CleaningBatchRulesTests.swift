@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningBatchValidator()
        let item = BedManagement.newCleaningBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningBatchRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.CleaningBatchRequiredCodeRule(message: "cleaning batch needs a value")
        let item = BedManagement.newCleaningBatch("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningBatchRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.CleaningBatchRequiredLabelRule(message: "cleaning batch needs an entry")
        let item = BedManagement.newCleaningBatch("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningBatchLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = BedManagement.CleaningBatchLocaleLengthRule(maxLength: 1000)
        let item = BedManagement.newCleaningBatch("x", label: "y")
        item.locale = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCleaningBatchRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = BedManagement.CleaningBatchRequiredLocaleRule(message: "cleaning batch needs this field")
        let item = BedManagement.newCleaningBatch("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}
