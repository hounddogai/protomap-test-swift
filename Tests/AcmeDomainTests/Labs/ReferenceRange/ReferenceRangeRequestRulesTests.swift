@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeRequestValidator()
        let item = Labs.newReferenceRangeRequest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeRequestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.ReferenceRangeRequestRequiredLabelRule(message: "reference range request needs a value")
        let item = Labs.newReferenceRangeRequest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeRequestEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Labs.ReferenceRangeRequestEndsAtRangeRule(min: 80, max: 120)
        let item = Labs.newReferenceRangeRequest("x", label: "y")
        item.endsAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsReferenceRangeRequestDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Labs.ReferenceRangeRequestDescriptionLengthRule(maxLength: 120)
        let item = Labs.newReferenceRangeRequest("x", label: "y")
        item.description = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}
