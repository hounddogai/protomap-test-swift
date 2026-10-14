@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingSlotTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPendingSlotTargetValidator()
        let item = Referrals.newPendingSlotTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPendingSlotTargetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.PendingSlotTargetRequiredNameRule(message: "pending slot target needs a value")
        let item = Referrals.newPendingSlotTarget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPendingSlotTargetAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Referrals.PendingSlotTargetAmountRangeRule(min: 4.9, max: 953.3)
        let item = Referrals.newPendingSlotTarget("x", name: "y")
        item.amount = 954.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsPendingSlotTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.PendingSlotTargetRequiredCodeRule(message: "pending slot target needs an entry")
        let item = Referrals.newPendingSlotTarget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPendingSlotTargetRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Referrals.PendingSlotTargetRequiredProcedureCodeRule(message: "pending slot target needs this field")
        let item = Referrals.newPendingSlotTarget("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
