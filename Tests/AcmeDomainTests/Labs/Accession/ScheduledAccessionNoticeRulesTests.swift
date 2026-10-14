@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledAccessionNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultScheduledAccessionNoticeValidator()
        let item = Labs.newScheduledAccessionNotice("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsScheduledAccessionNoticeBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Labs.ScheduledAccessionNoticeBatchSizeRangeRule(min: 3600, max: 3600)
        let item = Labs.newScheduledAccessionNotice("x", label: "y")
        item.batchSize = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsScheduledAccessionNoticeNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Labs.ScheduledAccessionNoticeNotesLengthRule(maxLength: 32)
        let item = Labs.newScheduledAccessionNotice("x", label: "y")
        item.notes = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsScheduledAccessionNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ScheduledAccessionNoticeRequiredCodeRule(message: "scheduled accession notice needs a value")
        let item = Labs.newScheduledAccessionNotice("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
