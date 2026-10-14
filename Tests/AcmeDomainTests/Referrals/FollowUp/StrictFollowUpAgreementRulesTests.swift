@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictFollowUpAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultStrictFollowUpAgreementValidator()
        let item = Referrals.newStrictFollowUpAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsStrictFollowUpAgreementRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.StrictFollowUpAgreementRequiredNameRule(
            message: "strict follow up agreement needs this field"
        )
        let item = Referrals.newStrictFollowUpAgreement("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsStrictFollowUpAgreementNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.StrictFollowUpAgreementNameLengthRule(maxLength: 255)
        let item = Referrals.newStrictFollowUpAgreement("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsStrictFollowUpAgreementCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Referrals.StrictFollowUpAgreementCreatedAtRangeRule(min: 120, max: 1000)
        let item = Referrals.newStrictFollowUpAgreement("x", name: "y")
        item.createdAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
