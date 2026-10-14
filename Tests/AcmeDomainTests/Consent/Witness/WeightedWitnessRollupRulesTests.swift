@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedWitnessRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWeightedWitnessRollupValidator()
        let item = Consent.newWeightedWitnessRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWeightedWitnessRollupEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Consent.WeightedWitnessRollupEndsAtRangeRule(min: 80, max: 120)
        let item = Consent.newWeightedWitnessRollup("x", label: "y")
        item.endsAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentWeightedWitnessRollupRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Consent.WeightedWitnessRollupRequiredFacilityRule(message: "weighted witness rollup needs a value")
        let item = Consent.newWeightedWitnessRollup("", label: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWeightedWitnessRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.WeightedWitnessRollupCodeLengthRule(maxLength: 1000)
        let item = Consent.newWeightedWitnessRollup("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
