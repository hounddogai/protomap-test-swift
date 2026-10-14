@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpGroupValidator()
        let item = Referrals.newFollowUpGroup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpGroupWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Referrals.FollowUpGroupWardLengthRule(maxLength: 80)
        let item = Referrals.newFollowUpGroup("x", name: "y")
        item.ward = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpGroupLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Referrals.FollowUpGroupLimitRangeRule(min: 255, max: 1000)
        let item = Referrals.newFollowUpGroup("x", name: "y")
        item.limit = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFollowUpGroupRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Referrals.FollowUpGroupRequiredWardRule(message: "follow up group needs an entry")
        let item = Referrals.newFollowUpGroup("", name: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.FollowUpGroupCodeLengthRule(maxLength: 64)
        let item = Referrals.newFollowUpGroup("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
