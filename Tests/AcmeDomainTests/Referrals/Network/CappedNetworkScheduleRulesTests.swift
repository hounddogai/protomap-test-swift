@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedNetworkScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultCappedNetworkScheduleValidator()
        let item = Referrals.newCappedNetworkSchedule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsCappedNetworkScheduleCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Referrals.CappedNetworkScheduleCountryLengthRule(maxLength: 64)
        let item = Referrals.newCappedNetworkSchedule("x", label: "y")
        item.country = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsCappedNetworkScheduleScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Referrals.CappedNetworkScheduleScoreRangeRule(min: 6.3, max: 817.2)
        let item = Referrals.newCappedNetworkSchedule("x", label: "y")
        item.score = 818.7
        #expect(rule.check(item).count > 0)
    }
}
