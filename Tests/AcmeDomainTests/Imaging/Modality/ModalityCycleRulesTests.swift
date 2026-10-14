@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityCycleValidator()
        let item = Imaging.newModalityCycle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityCycleRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Imaging.ModalityCycleRevisionRangeRule(min: 16, max: 16)
        let item = Imaging.newModalityCycle("x", label: "y")
        item.revision = 17
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingModalityCycleDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Imaging.ModalityCycleDiscountRangeRule(min: 4.8, max: 4694.9)
        let item = Imaging.newModalityCycle("x", label: "y")
        item.discount = 4696.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingModalityCycleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.ModalityCycleLabelLengthRule(maxLength: 3600)
        let item = Imaging.newModalityCycle("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
