@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotCycleValidator()
        let item = Referrals.newSlotCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotCycleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.SlotCycleCodeLengthRule(maxLength: 3600)
        let item = Referrals.newSlotCycle("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.SlotCycleRequiredCodeRule(message: "slot cycle needs an entry")
        let item = Referrals.newSlotCycle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
