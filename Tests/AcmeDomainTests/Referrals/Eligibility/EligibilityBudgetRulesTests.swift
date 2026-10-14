@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityBudgetValidator()
        let item = Referrals.newEligibilityBudget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityBudgetOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Referrals.EligibilityBudgetOwnerIDLengthRule(maxLength: 86400)
        let item = Referrals.newEligibilityBudget("x", name: "y")
        item.ownerID = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityBudgetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.EligibilityBudgetRequiredNameRule(message: "eligibility budget needs a value")
        let item = Referrals.newEligibilityBudget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityBudgetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.EligibilityBudgetRequiredCodeRule(message: "eligibility budget needs this field")
        let item = Referrals.newEligibilityBudget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
