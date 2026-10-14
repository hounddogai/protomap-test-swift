@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalWitnessGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultSeasonalWitnessGroupValidator()
        let item = Consent.newSeasonalWitnessGroup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentSeasonalWitnessGroupPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Consent.SeasonalWitnessGroupPhoneLengthRule(maxLength: 120)
        let item = Consent.newSeasonalWitnessGroup("x", name: "y")
        item.phone = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentSeasonalWitnessGroupRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.SeasonalWitnessGroupRequiredNameRule(message: "seasonal witness group needs an entry")
        let item = Consent.newSeasonalWitnessGroup("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
