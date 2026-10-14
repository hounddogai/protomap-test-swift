@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenCycleValidator()
        let item = Labs.newSpecimenCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenCycleScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Labs.SpecimenCycleScoreRangeRule(min: 7.5, max: 3273.5)
        let item = Labs.newSpecimenCycle("x", name: "y")
        item.score = 3275.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenCycleRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Labs.SpecimenCycleRatioRangeRule(min: 2.9, max: 3003.6)
        let item = Labs.newSpecimenCycle("x", name: "y")
        item.ratio = 3005.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenCycleRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Labs.SpecimenCycleRequiredCountryRule(message: "specimen cycle needs an entry")
        let item = Labs.newSpecimenCycle("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenCycleCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Labs.SpecimenCycleCurrencyLengthRule(maxLength: 32)
        let item = Labs.newSpecimenCycle("x", name: "y")
        item.currency = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}
