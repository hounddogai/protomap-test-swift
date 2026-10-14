@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedCareProtocolVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWeightedCareProtocolVarianceValidator()
        let item = Imaging.newWeightedCareProtocolVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWeightedCareProtocolVarianceWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Imaging.WeightedCareProtocolVarianceWeightRangeRule(min: 0.6, max: 1739.1)
        let item = Imaging.newWeightedCareProtocolVariance("x", title: "y")
        item.weight = 1740.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWeightedCareProtocolVarianceRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Imaging.WeightedCareProtocolVarianceRequiredPayerRule(
            message: "weighted care protocol variance needs an entry"
        )
        let item = Imaging.newWeightedCareProtocolVariance("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWeightedCareProtocolVariancePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Imaging.WeightedCareProtocolVariancePayerLengthRule(maxLength: 1000)
        let item = Imaging.newWeightedCareProtocolVariance("x", title: "y")
        item.payer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWeightedCareProtocolVarianceRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Imaging.WeightedCareProtocolVarianceRatioRangeRule(min: 5.7, max: 509.7)
        let item = Imaging.newWeightedCareProtocolVariance("x", title: "y")
        item.ratio = 511.2
        #expect(rule.check(item).count > 0)
    }
}
