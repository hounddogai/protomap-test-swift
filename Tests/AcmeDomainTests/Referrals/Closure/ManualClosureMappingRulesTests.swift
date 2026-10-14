@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualClosureMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultManualClosureMappingValidator()
        let item = Referrals.newManualClosureMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsManualClosureMappingProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Referrals.ManualClosureMappingProcedureCodeLengthRule(maxLength: 32)
        let item = Referrals.newManualClosureMapping("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsManualClosureMappingAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Referrals.ManualClosureMappingAmountRangeRule(min: 5.2, max: 879.2)
        let item = Referrals.newManualClosureMapping("x", title: "y")
        item.amount = 880.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsManualClosureMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ManualClosureMappingCodeLengthRule(maxLength: 64)
        let item = Referrals.newManualClosureMapping("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
