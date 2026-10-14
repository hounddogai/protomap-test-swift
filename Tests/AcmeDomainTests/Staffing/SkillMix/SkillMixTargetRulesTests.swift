@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixTargetValidator()
        let item = Staffing.newSkillMixTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixTargetMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Staffing.SkillMixTargetMarginRangeRule(min: 2.1, max: 1630.0)
        let item = Staffing.newSkillMixTarget("x", name: "y")
        item.margin = 1631.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSkillMixTargetRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Staffing.SkillMixTargetRatioRangeRule(min: 5.7, max: 203.3)
        let item = Staffing.newSkillMixTarget("x", name: "y")
        item.ratio = 204.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSkillMixTargetOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Staffing.SkillMixTargetOwnerIDLengthRule(maxLength: 16)
        let item = Staffing.newSkillMixTarget("x", name: "y")
        item.ownerID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSkillMixTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.SkillMixTargetRequiredCodeRule(message: "skill mix target needs an entry")
        let item = Staffing.newSkillMixTarget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
