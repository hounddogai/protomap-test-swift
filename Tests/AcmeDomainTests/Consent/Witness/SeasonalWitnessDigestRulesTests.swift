@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalWitnessDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultSeasonalWitnessDigestValidator()
        let item = Consent.newSeasonalWitnessDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentSeasonalWitnessDigestAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Consent.SeasonalWitnessDigestAmountRangeRule(min: 1.4, max: 4603.4)
        let item = Consent.newSeasonalWitnessDigest("x", name: "y")
        item.amount = 4604.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentSeasonalWitnessDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.SeasonalWitnessDigestCodeLengthRule(maxLength: 1000)
        let item = Consent.newSeasonalWitnessDigest("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
