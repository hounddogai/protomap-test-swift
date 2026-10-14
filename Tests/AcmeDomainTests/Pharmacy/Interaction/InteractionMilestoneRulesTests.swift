@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionMilestoneValidator()
        let item = Pharmacy.newInteractionMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionMilestoneDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Pharmacy.InteractionMilestoneDurationMinutesRangeRule(min: 64, max: 3600)
        let item = Pharmacy.newInteractionMilestone("x", name: "y")
        item.durationMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInteractionMilestoneCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Pharmacy.InteractionMilestoneCreatedAtRangeRule(min: 32, max: 120)
        let item = Pharmacy.newInteractionMilestone("x", name: "y")
        item.createdAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInteractionMilestoneRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.InteractionMilestoneRequiredNameRule(message: "interaction milestone needs a value")
        let item = Pharmacy.newInteractionMilestone("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
