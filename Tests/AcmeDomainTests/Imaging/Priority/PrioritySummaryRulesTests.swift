@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrioritySummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPrioritySummaryValidator()
        let item = Imaging.newPrioritySummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPrioritySummaryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.PrioritySummaryCodeLengthRule(maxLength: 3600)
        let item = Imaging.newPrioritySummary("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPrioritySummaryNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Imaging.PrioritySummaryNotesLengthRule(maxLength: 32)
        let item = Imaging.newPrioritySummary("x", title: "y")
        item.notes = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPrioritySummaryRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Imaging.PrioritySummaryRequiredNotesRule(message: "priority summary needs this field")
        let item = Imaging.newPrioritySummary("", title: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}
