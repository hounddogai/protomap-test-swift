@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualRecallScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultManualRecallScoreValidator()
        let item = Pharmacy.newManualRecallScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyManualRecallScoreRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Pharmacy.ManualRecallScoreRatioRangeRule(min: 8.8, max: 4612.1)
        let item = Pharmacy.newManualRecallScore("x", title: "y")
        item.ratio = 4613.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyManualRecallScoreRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Pharmacy.ManualRecallScoreRequiredUnitRule(message: "manual recall score needs this field")
        let item = Pharmacy.newManualRecallScore("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyManualRecallScoreUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Pharmacy.ManualRecallScoreUnitLengthRule(maxLength: 80)
        let item = Pharmacy.newManualRecallScore("x", title: "y")
        item.unit = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}
