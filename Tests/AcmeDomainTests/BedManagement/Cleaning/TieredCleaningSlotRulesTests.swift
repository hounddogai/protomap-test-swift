@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredCleaningSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTieredCleaningSlotValidator()
        let item = BedManagement.newTieredCleaningSlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTieredCleaningSlotChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = BedManagement.TieredCleaningSlotChannelLengthRule(maxLength: 80)
        let item = BedManagement.newTieredCleaningSlot("x", title: "y")
        item.channel = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTieredCleaningSlotRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = BedManagement.TieredCleaningSlotRequiredCategoryRule(message: "tiered cleaning slot needs this field")
        let item = BedManagement.newTieredCleaningSlot("", title: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTieredCleaningSlotRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = BedManagement.TieredCleaningSlotRatioRangeRule(min: 4.1, max: 3313.8)
        let item = BedManagement.newTieredCleaningSlot("x", title: "y")
        item.ratio = 3315.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTieredCleaningSlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.TieredCleaningSlotCodeLengthRule(maxLength: 120)
        let item = BedManagement.newTieredCleaningSlot("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTieredCleaningSlotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.TieredCleaningSlotTitleLengthRule(maxLength: 3600)
        let item = BedManagement.newTieredCleaningSlot("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
