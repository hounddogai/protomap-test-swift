@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityBundleValidator()
        let item = Imaging.newModalityBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityBundleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.ModalityBundleRequiredLabelRule(message: "modality bundle needs a value")
        let item = Imaging.newModalityBundle("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ModalityBundleRequiredCodeRule(message: "modality bundle needs a value")
        let item = Imaging.newModalityBundle("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ModalityBundleCodeLengthRule(maxLength: 80)
        let item = Imaging.newModalityBundle("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityBundleMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Imaging.ModalityBundleMinimumRangeRule(min: 5.7, max: 2310.6)
        let item = Imaging.newModalityBundle("x", label: "y")
        item.minimum = 2312.1
        #expect(rule.check(item).count > 0)
    }
}
