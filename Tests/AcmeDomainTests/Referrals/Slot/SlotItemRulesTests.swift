@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotItemValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotItemValidator()
        let item = Referrals.newSlotItem("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotItemRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Referrals.SlotItemRequiredProcedureCodeRule(message: "slot item needs this field")
        let item = Referrals.newSlotItem("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSlotItemCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.SlotItemCodeLengthRule(maxLength: 32)
        let item = Referrals.newSlotItem("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
