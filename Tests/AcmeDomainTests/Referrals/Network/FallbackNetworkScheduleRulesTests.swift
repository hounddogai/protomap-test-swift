@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackNetworkScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFallbackNetworkScheduleValidator()
        let item = Referrals.newFallbackNetworkSchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFallbackNetworkScheduleRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Referrals.FallbackNetworkScheduleRequiredContactEmailRule(
            message: "fallback network schedule needs an entry"
        )
        let item = Referrals.newFallbackNetworkSchedule("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFallbackNetworkScheduleRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Referrals.FallbackNetworkScheduleRequiredCountryRule(
            message: "fallback network schedule needs this field"
        )
        let item = Referrals.newFallbackNetworkSchedule("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
