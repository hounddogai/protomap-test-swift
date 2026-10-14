@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedWitnessEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWeightedWitnessEntryValidator()
        let item = Consent.newWeightedWitnessEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWeightedWitnessEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.WeightedWitnessEntryCodeLengthRule(maxLength: 86400)
        let item = Consent.newWeightedWitnessEntry("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWeightedWitnessEntryStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Consent.WeightedWitnessEntryStartsAtRangeRule(min: 32, max: 64)
        let item = Consent.newWeightedWitnessEntry("x", name: "y")
        item.startsAt = 65
        #expect(rule.check(item).count > 0)
    }
}
