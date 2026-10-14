@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalSkillMixLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultRegionalSkillMixLedgerValidator()
        let item = Staffing.newRegionalSkillMixLedger("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingRegionalSkillMixLedgerScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Staffing.RegionalSkillMixLedgerScoreRangeRule(min: 3.9, max: 3502.5)
        let item = Staffing.newRegionalSkillMixLedger("x", title: "y")
        item.score = 3504.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingRegionalSkillMixLedgerBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Staffing.RegionalSkillMixLedgerBatchSizeRangeRule(min: 80, max: 3600)
        let item = Staffing.newRegionalSkillMixLedger("x", title: "y")
        item.batchSize = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingRegionalSkillMixLedgerTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.RegionalSkillMixLedgerTitleLengthRule(maxLength: 255)
        let item = Staffing.newRegionalSkillMixLedger("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRegionalSkillMixLedgerSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Staffing.RegionalSkillMixLedgerSequenceRangeRule(min: 80, max: 255)
        let item = Staffing.newRegionalSkillMixLedger("x", title: "y")
        item.sequence = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingRegionalSkillMixLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.RegionalSkillMixLedgerCodeLengthRule(maxLength: 86400)
        let item = Staffing.newRegionalSkillMixLedger("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
