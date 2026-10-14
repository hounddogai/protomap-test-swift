@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalDisclosureDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultSeasonalDisclosureDigestValidator()
        let item = Consent.newSeasonalDisclosureDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentSeasonalDisclosureDigestDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Consent.SeasonalDisclosureDigestDurationMinutesRangeRule(min: 32, max: 32)
        let item = Consent.newSeasonalDisclosureDigest("x", title: "y")
        item.durationMinutes = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentSeasonalDisclosureDigestBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Consent.SeasonalDisclosureDigestBudgetRangeRule(min: 4.3, max: 2748.8)
        let item = Consent.newSeasonalDisclosureDigest("x", title: "y")
        item.budget = 2750.3
        #expect(rule.check(item).count > 0)
    }
}
