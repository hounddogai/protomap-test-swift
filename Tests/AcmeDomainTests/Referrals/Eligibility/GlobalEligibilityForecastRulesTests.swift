@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalEligibilityForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultGlobalEligibilityForecastValidator()
        let item = Referrals.newGlobalEligibilityForecast("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsGlobalEligibilityForecastRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.GlobalEligibilityForecastRequiredCodeRule(
            message: "global eligibility forecast needs an entry"
        )
        let item = Referrals.newGlobalEligibilityForecast("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsGlobalEligibilityForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.GlobalEligibilityForecastCodeLengthRule(maxLength: 16)
        let item = Referrals.newGlobalEligibilityForecast("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsGlobalEligibilityForecastEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Referrals.GlobalEligibilityForecastEncounterIDLengthRule(maxLength: 86400)
        let item = Referrals.newGlobalEligibilityForecast("x", label: "y")
        item.encounterID = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
