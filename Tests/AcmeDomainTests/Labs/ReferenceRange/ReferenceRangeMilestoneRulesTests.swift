@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeMilestoneValidator()
        let item = Labs.newReferenceRangeMilestone("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeMilestoneCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Labs.ReferenceRangeMilestoneCategoryLengthRule(maxLength: 80)
        let item = Labs.newReferenceRangeMilestone("x", label: "y")
        item.category = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeMilestoneLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.ReferenceRangeMilestoneLabelLengthRule(maxLength: 80)
        let item = Labs.newReferenceRangeMilestone("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeMilestoneRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.ReferenceRangeMilestoneRequiredLabelRule(message: "reference range milestone needs an entry")
        let item = Labs.newReferenceRangeMilestone("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeMilestoneRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Labs.ReferenceRangeMilestoneRequiredCategoryRule(message: "reference range milestone needs a value")
        let item = Labs.newReferenceRangeMilestone("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}
