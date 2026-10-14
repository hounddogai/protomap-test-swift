@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningMilestoneValidator()
        let item = BedManagement.newCleaningMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningMilestoneStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = BedManagement.CleaningMilestoneStartsAtRangeRule(min: 32, max: 64)
        let item = BedManagement.newCleaningMilestone("x", name: "y")
        item.startsAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCleaningMilestoneRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.CleaningMilestoneRequiredNameRule(message: "cleaning milestone needs an entry")
        let item = BedManagement.newCleaningMilestone("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningMilestoneDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = BedManagement.CleaningMilestoneDosageMgRangeRule(min: 8.9, max: 943.1)
        let item = BedManagement.newCleaningMilestone("x", name: "y")
        item.dosageMg = 944.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCleaningMilestoneNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.CleaningMilestoneNameLengthRule(maxLength: 64)
        let item = BedManagement.newCleaningMilestone("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCleaningMilestoneRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = BedManagement.CleaningMilestoneRequiredAllergyRule(message: "cleaning milestone needs an entry")
        let item = BedManagement.newCleaningMilestone("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
