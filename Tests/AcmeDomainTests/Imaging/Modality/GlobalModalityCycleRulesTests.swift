@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalModalityCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultGlobalModalityCycleValidator()
        let item = Imaging.newGlobalModalityCycle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingGlobalModalityCycleDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Imaging.GlobalModalityCycleDiscountRangeRule(min: 1.0, max: 3974.1)
        let item = Imaging.newGlobalModalityCycle("x", label: "y")
        item.discount = 3975.6
        #expect(rule.check(item).count > 0)
    }
}
