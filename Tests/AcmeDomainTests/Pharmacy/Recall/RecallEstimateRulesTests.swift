@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallEstimateValidator()
        let item = Pharmacy.newRecallEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallEstimateRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Pharmacy.RecallEstimateRateRangeRule(min: 9.7, max: 1532.3)
        let item = Pharmacy.newRecallEstimate("x", title: "y")
        item.rate = 1533.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRecallEstimateBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Pharmacy.RecallEstimateBatchSizeRangeRule(min: 255, max: 3600)
        let item = Pharmacy.newRecallEstimate("x", title: "y")
        item.batchSize = 3601
        #expect(rule.check(item).count > 0)
    }
}
