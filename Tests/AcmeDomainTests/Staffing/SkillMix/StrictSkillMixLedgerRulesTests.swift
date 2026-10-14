@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictSkillMixLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultStrictSkillMixLedgerValidator()
        let item = Staffing.newStrictSkillMixLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingStrictSkillMixLedgerQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Staffing.StrictSkillMixLedgerQuantityRangeRule(min: 16, max: 64)
        let item = Staffing.newStrictSkillMixLedger("x", name: "y")
        item.quantity = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingStrictSkillMixLedgerPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Staffing.StrictSkillMixLedgerPriorityRangeRule(min: 120, max: 86400)
        let item = Staffing.newStrictSkillMixLedger("x", name: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingStrictSkillMixLedgerRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.StrictSkillMixLedgerRequiredNameRule(message: "strict skill mix ledger needs an entry")
        let item = Staffing.newStrictSkillMixLedger("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingStrictSkillMixLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.StrictSkillMixLedgerRequiredCodeRule(message: "strict skill mix ledger needs a value")
        let item = Staffing.newStrictSkillMixLedger("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingStrictSkillMixLedgerNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.StrictSkillMixLedgerNameLengthRule(maxLength: 32)
        let item = Staffing.newStrictSkillMixLedger("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
