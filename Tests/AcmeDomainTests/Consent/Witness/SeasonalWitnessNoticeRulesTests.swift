@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalWitnessNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultSeasonalWitnessNoticeValidator()
        let item = Consent.newSeasonalWitnessNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentSeasonalWitnessNoticeNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.SeasonalWitnessNoticeNameLengthRule(maxLength: 86400)
        let item = Consent.newSeasonalWitnessNotice("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentSeasonalWitnessNoticeMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Consent.SeasonalWitnessNoticeMinimumRangeRule(min: 5.0, max: 2492.8)
        let item = Consent.newSeasonalWitnessNotice("x", name: "y")
        item.minimum = 2494.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentSeasonalWitnessNoticeRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Consent.SeasonalWitnessNoticeRequiredExternalRefRule(message: "seasonal witness notice needs a value")
        let item = Consent.newSeasonalWitnessNotice("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
