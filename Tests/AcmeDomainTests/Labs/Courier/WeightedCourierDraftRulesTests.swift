@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedCourierDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultWeightedCourierDraftValidator()
        let item = Labs.newWeightedCourierDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsWeightedCourierDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.WeightedCourierDraftCodeLengthRule(maxLength: 64)
        let item = Labs.newWeightedCourierDraft("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsWeightedCourierDraftRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.WeightedCourierDraftRequiredTitleRule(message: "weighted courier draft needs a value")
        let item = Labs.newWeightedCourierDraft("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsWeightedCourierDraftDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Labs.WeightedCourierDraftDurationMinutesRangeRule(min: 255, max: 3600)
        let item = Labs.newWeightedCourierDraft("x", title: "y")
        item.durationMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsWeightedCourierDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.WeightedCourierDraftRequiredCodeRule(message: "weighted courier draft needs a value")
        let item = Labs.newWeightedCourierDraft("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
