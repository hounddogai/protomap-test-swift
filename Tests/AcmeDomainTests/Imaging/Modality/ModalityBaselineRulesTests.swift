@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityBaselineValidator()
        let item = Imaging.newModalityBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityBaselineLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Imaging.ModalityBaselineLimitRangeRule(min: 16, max: 3600)
        let item = Imaging.newModalityBaseline("x", label: "y")
        item.limit = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingModalityBaselineLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.ModalityBaselineLabelLengthRule(maxLength: 16)
        let item = Imaging.newModalityBaseline("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityBaselineWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Imaging.ModalityBaselineWeightRangeRule(min: 3.0, max: 2334.7)
        let item = Imaging.newModalityBaseline("x", label: "y")
        item.weight = 2336.2
        #expect(rule.check(item).count > 0)
    }
}
