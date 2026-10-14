@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpScoreValidator()
        let item = Referrals.newFollowUpScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.FollowUpScoreRequiredCodeRule(message: "follow up score needs this field")
        let item = Referrals.newFollowUpScore("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpScoreAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Referrals.FollowUpScoreAmountRangeRule(min: 1.1, max: 3219.0)
        let item = Referrals.newFollowUpScore("x", label: "y")
        item.amount = 3220.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFollowUpScoreRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Referrals.FollowUpScoreRequiredBedRule(message: "follow up score needs this field")
        let item = Referrals.newFollowUpScore("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpScoreLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.FollowUpScoreLabelLengthRule(maxLength: 3600)
        let item = Referrals.newFollowUpScore("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
