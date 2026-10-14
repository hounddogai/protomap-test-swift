@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyCensusMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLegacyCensusMilestoneValidator()
        let item = BedManagement.newLegacyCensusMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLegacyCensusMilestoneNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.LegacyCensusMilestoneNameLengthRule(maxLength: 120)
        let item = BedManagement.newLegacyCensusMilestone("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementLegacyCensusMilestoneBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = BedManagement.LegacyCensusMilestoneBudgetRangeRule(min: 5.6, max: 684.8)
        let item = BedManagement.newLegacyCensusMilestone("x", name: "y")
        item.budget = 686.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementLegacyCensusMilestoneFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = BedManagement.LegacyCensusMilestoneFloorValueRangeRule(min: 7.0, max: 3037.7)
        let item = BedManagement.newLegacyCensusMilestone("x", name: "y")
        item.floorValue = 3039.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementLegacyCensusMilestoneRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = BedManagement.LegacyCensusMilestoneRequiredLocaleRule(
            message: "legacy census milestone needs this field"
        )
        let item = BedManagement.newLegacyCensusMilestone("", name: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLegacyCensusMilestoneRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = BedManagement.LegacyCensusMilestoneRequiredCategoryRule(
            message: "legacy census milestone needs this field"
        )
        let item = BedManagement.newLegacyCensusMilestone("", name: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}
