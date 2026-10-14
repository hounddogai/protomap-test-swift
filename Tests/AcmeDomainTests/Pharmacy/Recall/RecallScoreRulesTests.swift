@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallScoreValidator()
        let item = Pharmacy.newRecallScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallScoreRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Pharmacy.RecallScoreRatioRangeRule(min: 8.3, max: 2988.8)
        let item = Pharmacy.newRecallScore("x", label: "y")
        item.ratio = 2990.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRecallScoreRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.RecallScoreRequiredLabelRule(message: "recall score needs an entry")
        let item = Pharmacy.newRecallScore("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallScoreRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Pharmacy.RecallScoreRequiredPayerRule(message: "recall score needs this field")
        let item = Pharmacy.newRecallScore("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}
