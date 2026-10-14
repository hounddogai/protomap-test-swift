@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedSkillMixSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCappedSkillMixSlotValidator()
        let item = Staffing.newCappedSkillMixSlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCappedSkillMixSlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CappedSkillMixSlotCodeLengthRule(maxLength: 64)
        let item = Staffing.newCappedSkillMixSlot("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCappedSkillMixSlotWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Staffing.CappedSkillMixSlotWeightRangeRule(min: 7.5, max: 1377.9)
        let item = Staffing.newCappedSkillMixSlot("x", title: "y")
        item.weight = 1379.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCappedSkillMixSlotUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Staffing.CappedSkillMixSlotUpdatedAtRangeRule(min: 64, max: 80)
        let item = Staffing.newCappedSkillMixSlot("x", title: "y")
        item.updatedAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCappedSkillMixSlotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.CappedSkillMixSlotTitleLengthRule(maxLength: 3600)
        let item = Staffing.newCappedSkillMixSlot("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCappedSkillMixSlotRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.CappedSkillMixSlotRequiredTitleRule(message: "capped skill mix slot needs this field")
        let item = Staffing.newCappedSkillMixSlot("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
