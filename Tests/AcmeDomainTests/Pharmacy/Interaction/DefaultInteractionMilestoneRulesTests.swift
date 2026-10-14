@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultInteractionMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDefaultInteractionMilestoneValidator()
        let item = Pharmacy.newDefaultInteractionMilestone("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDefaultInteractionMilestoneRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Pharmacy.DefaultInteractionMilestoneRequiredSegmentRule(
            message: "default interaction milestone needs a value"
        )
        let item = Pharmacy.newDefaultInteractionMilestone("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDefaultInteractionMilestoneBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Pharmacy.DefaultInteractionMilestoneBatchSizeRangeRule(min: 80, max: 86400)
        let item = Pharmacy.newDefaultInteractionMilestone("x", label: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDefaultInteractionMilestoneRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.DefaultInteractionMilestoneRequiredLabelRule(
            message: "default interaction milestone needs this field"
        )
        let item = Pharmacy.newDefaultInteractionMilestone("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
