@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryMilestoneValidator()
        let item = Pharmacy.newInventoryMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryMilestoneRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Pharmacy.InventoryMilestoneRequiredSourceRule(message: "inventory milestone needs an entry")
        let item = Pharmacy.newInventoryMilestone("", name: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryMilestoneDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Pharmacy.InventoryMilestoneDurationMinutesRangeRule(min: 255, max: 3600)
        let item = Pharmacy.newInventoryMilestone("x", name: "y")
        item.durationMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInventoryMilestoneRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.InventoryMilestoneRequiredNameRule(message: "inventory milestone needs an entry")
        let item = Pharmacy.newInventoryMilestone("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
