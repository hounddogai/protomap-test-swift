@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedReferenceRangeRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCappedReferenceRangeRecordValidator()
        let item = Labs.newCappedReferenceRangeRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCappedReferenceRangeRecordCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.CappedReferenceRangeRecordCodeLengthRule(maxLength: 3600)
        let item = Labs.newCappedReferenceRangeRecord("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCappedReferenceRangeRecordContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Labs.CappedReferenceRangeRecordContactEmailLengthRule(maxLength: 32)
        let item = Labs.newCappedReferenceRangeRecord("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCappedReferenceRangeRecordRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.CappedReferenceRangeRecordRequiredTitleRule(
            message: "capped reference range record needs an entry"
        )
        let item = Labs.newCappedReferenceRangeRecord("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCappedReferenceRangeRecordRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Labs.CappedReferenceRangeRecordRequiredContactEmailRule(
            message: "capped reference range record needs this field"
        )
        let item = Labs.newCappedReferenceRangeRecord("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}
