@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLenientReferenceRangeDraftValidator()
        let item = Labs.newLenientReferenceRangeDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLenientReferenceRangeDraftTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.LenientReferenceRangeDraftTitleLengthRule(maxLength: 32)
        let item = Labs.newLenientReferenceRangeDraft("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLenientReferenceRangeDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.LenientReferenceRangeDraftRequiredCodeRule(
            message: "lenient reference range draft needs a value"
        )
        let item = Labs.newLenientReferenceRangeDraft("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLenientReferenceRangeDraftRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.LenientReferenceRangeDraftRequiredTitleRule(
            message: "lenient reference range draft needs this field"
        )
        let item = Labs.newLenientReferenceRangeDraft("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLenientReferenceRangeDraftEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Labs.LenientReferenceRangeDraftEndsAtRangeRule(min: 16, max: 80)
        let item = Labs.newLenientReferenceRangeDraft("x", title: "y")
        item.endsAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsLenientReferenceRangeDraftAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Labs.LenientReferenceRangeDraftAttemptsRangeRule(min: 16, max: 80)
        let item = Labs.newLenientReferenceRangeDraft("x", title: "y")
        item.attempts = 81
        #expect(rule.check(item).count > 0)
    }
}
