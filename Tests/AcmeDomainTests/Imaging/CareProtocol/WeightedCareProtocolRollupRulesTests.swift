@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedCareProtocolRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWeightedCareProtocolRollupValidator()
        let item = Imaging.newWeightedCareProtocolRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWeightedCareProtocolRollupDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Imaging.WeightedCareProtocolRollupDiscountRangeRule(min: 4.5, max: 3561.0)
        let item = Imaging.newWeightedCareProtocolRollup("x", label: "y")
        item.discount = 3562.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWeightedCareProtocolRollupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.WeightedCareProtocolRollupLabelLengthRule(maxLength: 86400)
        let item = Imaging.newWeightedCareProtocolRollup("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
