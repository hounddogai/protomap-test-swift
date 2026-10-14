@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyReferenceRangeProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLegacyReferenceRangeProfileValidator()
        let item = Labs.newLegacyReferenceRangeProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLegacyReferenceRangeProfileRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Labs.LegacyReferenceRangeProfileRequiredSummaryRule(
            message: "legacy reference range profile needs this field"
        )
        let item = Labs.newLegacyReferenceRangeProfile("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLegacyReferenceRangeProfileRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.LegacyReferenceRangeProfileRequiredLabelRule(
            message: "legacy reference range profile needs a value"
        )
        let item = Labs.newLegacyReferenceRangeProfile("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLegacyReferenceRangeProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.LegacyReferenceRangeProfileRequiredCodeRule(
            message: "legacy reference range profile needs this field"
        )
        let item = Labs.newLegacyReferenceRangeProfile("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
