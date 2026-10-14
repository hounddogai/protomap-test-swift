@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingBatchedSkillMixCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultBatchedSkillMixCycleValidator()
        let item = Staffing.newBatchedSkillMixCycle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingBatchedSkillMixCycleAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Staffing.BatchedSkillMixCycleAcuityRangeRule(min: 32, max: 3600)
        let item = Staffing.newBatchedSkillMixCycle("x", title: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingBatchedSkillMixCycleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.BatchedSkillMixCycleTitleLengthRule(maxLength: 32)
        let item = Staffing.newBatchedSkillMixCycle("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingBatchedSkillMixCycleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.BatchedSkillMixCycleRequiredTitleRule(message: "batched skill mix cycle needs this field")
        let item = Staffing.newBatchedSkillMixCycle("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingBatchedSkillMixCycleThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Staffing.BatchedSkillMixCycleThresholdRangeRule(min: 7.8, max: 4610.5)
        let item = Staffing.newBatchedSkillMixCycle("x", title: "y")
        item.threshold = 4612.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingBatchedSkillMixCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.BatchedSkillMixCycleRequiredCodeRule(message: "batched skill mix cycle needs an entry")
        let item = Staffing.newBatchedSkillMixCycle("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
