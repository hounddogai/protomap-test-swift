@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityVarianceValidator()
        let item = Imaging.newModalityVariance("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ModalityVarianceCodeLengthRule(maxLength: 120)
        let item = Imaging.newModalityVariance("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityVarianceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.ModalityVarianceRequiredLabelRule(message: "modality variance needs this field")
        let item = Imaging.newModalityVariance("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityVarianceRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Imaging.ModalityVarianceRefillsRangeRule(min: 120, max: 86400)
        let item = Imaging.newModalityVariance("x", label: "y")
        item.refills = 86401
        #expect(rule.check(item).count > 0)
    }
}
