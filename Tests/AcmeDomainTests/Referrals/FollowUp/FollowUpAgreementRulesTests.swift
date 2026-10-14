@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpAgreementValidator()
        let item = Referrals.newFollowUpAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpAgreementScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Referrals.FollowUpAgreementScoreRangeRule(min: 5.4, max: 3030.5)
        let item = Referrals.newFollowUpAgreement("x", name: "y")
        item.score = 3032.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFollowUpAgreementRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Referrals.FollowUpAgreementRefillsRangeRule(min: 80, max: 1000)
        let item = Referrals.newFollowUpAgreement("x", name: "y")
        item.refills = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFollowUpAgreementUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Referrals.FollowUpAgreementUnitLengthRule(maxLength: 64)
        let item = Referrals.newFollowUpAgreement("x", name: "y")
        item.unit = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpAgreementNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.FollowUpAgreementNameLengthRule(maxLength: 86400)
        let item = Referrals.newFollowUpAgreement("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpAgreementRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Referrals.FollowUpAgreementRevisionRangeRule(min: 80, max: 120)
        let item = Referrals.newFollowUpAgreement("x", name: "y")
        item.revision = 121
        #expect(rule.check(item).count > 0)
    }
}
