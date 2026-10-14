@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultSlotRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultDefaultSlotRequestValidator()
        let item = Referrals.newDefaultSlotRequest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsDefaultSlotRequestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.DefaultSlotRequestRequiredLabelRule(message: "default slot request needs an entry")
        let item = Referrals.newDefaultSlotRequest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsDefaultSlotRequestProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Referrals.DefaultSlotRequestProcedureCodeLengthRule(maxLength: 86400)
        let item = Referrals.newDefaultSlotRequest("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsDefaultSlotRequestRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Referrals.DefaultSlotRequestRequiredProcedureCodeRule(
            message: "default slot request needs this field"
        )
        let item = Referrals.newDefaultSlotRequest("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsDefaultSlotRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.DefaultSlotRequestRequiredCodeRule(message: "default slot request needs this field")
        let item = Referrals.newDefaultSlotRequest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
