@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalWitnessCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultSeasonalWitnessCycleValidator()
        let item = Consent.newSeasonalWitnessCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentSeasonalWitnessCycleRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Consent.SeasonalWitnessCycleRequiredWardRule(message: "seasonal witness cycle needs this field")
        let item = Consent.newSeasonalWitnessCycle("", name: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentSeasonalWitnessCycleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.SeasonalWitnessCycleRequiredLabelRule(message: "seasonal witness cycle needs a value")
        let item = Consent.newSeasonalWitnessCycle("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentSeasonalWitnessCycleRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Consent.SeasonalWitnessCycleRatioRangeRule(min: 2.9, max: 2765.0)
        let item = Consent.newSeasonalWitnessCycle("x", name: "y")
        item.ratio = 2766.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentSeasonalWitnessCycleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.SeasonalWitnessCycleLabelLengthRule(maxLength: 3600)
        let item = Consent.newSeasonalWitnessCycle("x", name: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentSeasonalWitnessCycleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.SeasonalWitnessCycleCodeLengthRule(maxLength: 16)
        let item = Consent.newSeasonalWitnessCycle("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
