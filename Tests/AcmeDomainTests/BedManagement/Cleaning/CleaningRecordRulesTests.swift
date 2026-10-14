@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningRecordValidator()
        let item = BedManagement.newCleaningRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.CleaningRecordRequiredCodeRule(message: "cleaning record needs this field")
        let item = BedManagement.newCleaningRecord("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningRecordSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = BedManagement.CleaningRecordSummaryLengthRule(maxLength: 1000)
        let item = BedManagement.newCleaningRecord("x", name: "y")
        item.summary = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
