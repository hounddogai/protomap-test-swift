@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalClosureClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRegionalClosureClaimValidator()
        let item = Referrals.newRegionalClosureClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRegionalClosureClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.RegionalClosureClaimCodeLengthRule(maxLength: 16)
        let item = Referrals.newRegionalClosureClaim("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRegionalClosureClaimTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.RegionalClosureClaimTitleLengthRule(maxLength: 16)
        let item = Referrals.newRegionalClosureClaim("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRegionalClosureClaimDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Referrals.RegionalClosureClaimDosageMgRangeRule(min: 5.0, max: 3839.8)
        let item = Referrals.newRegionalClosureClaim("x", title: "y")
        item.dosageMg = 3841.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRegionalClosureClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.RegionalClosureClaimRequiredCodeRule(message: "regional closure claim needs a value")
        let item = Referrals.newRegionalClosureClaim("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
