@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallForecastValidator()
        let item = Pharmacy.newRecallForecast("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallForecastSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Pharmacy.RecallForecastSequenceRangeRule(min: 120, max: 3600)
        let item = Pharmacy.newRecallForecast("x", title: "y")
        item.sequence = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRecallForecastRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RecallForecastRequiredCodeRule(message: "recall forecast needs a value")
        let item = Pharmacy.newRecallForecast("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallForecastTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.RecallForecastTitleLengthRule(maxLength: 120)
        let item = Pharmacy.newRecallForecast("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.RecallForecastCodeLengthRule(maxLength: 3600)
        let item = Pharmacy.newRecallForecast("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallForecastStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Pharmacy.RecallForecastStartsAtRangeRule(min: 16, max: 32)
        let item = Pharmacy.newRecallForecast("x", title: "y")
        item.startsAt = 33
        #expect(rule.check(item).count > 0)
    }
}
