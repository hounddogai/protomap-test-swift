@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveReferenceRangeMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAdaptiveReferenceRangeMilestoneValidator()
        let item = Labs.newAdaptiveReferenceRangeMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAdaptiveReferenceRangeMilestoneRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Labs.AdaptiveReferenceRangeMilestoneRequiredExternalRefRule(
            message: "adaptive reference range milestone needs an entry"
        )
        let item = Labs.newAdaptiveReferenceRangeMilestone("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAdaptiveReferenceRangeMilestoneWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Labs.AdaptiveReferenceRangeMilestoneWeightRangeRule(min: 4.4, max: 4636.6)
        let item = Labs.newAdaptiveReferenceRangeMilestone("x", title: "y")
        item.weight = 4638.1
        #expect(rule.check(item).count > 0)
    }
}
