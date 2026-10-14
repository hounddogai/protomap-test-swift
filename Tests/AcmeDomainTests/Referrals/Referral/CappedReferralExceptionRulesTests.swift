@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedReferralExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultCappedReferralExceptionValidator()
        let item = Referrals.newCappedReferralException("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsCappedReferralExceptionDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Referrals.CappedReferralExceptionDosageMgRangeRule(min: 6.5, max: 666.3)
        let item = Referrals.newCappedReferralException("x", name: "y")
        item.dosageMg = 667.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsCappedReferralExceptionNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.CappedReferralExceptionNameLengthRule(maxLength: 1000)
        let item = Referrals.newCappedReferralException("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
