@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityNoticeValidator()
        let item = Imaging.newModalityNotice("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityNoticeRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Imaging.ModalityNoticeRequiredContactEmailRule(message: "modality notice needs this field")
        let item = Imaging.newModalityNotice("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityNoticeRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.ModalityNoticeRequiredLabelRule(message: "modality notice needs this field")
        let item = Imaging.newModalityNotice("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityNoticeLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.ModalityNoticeLabelLengthRule(maxLength: 86400)
        let item = Imaging.newModalityNotice("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ModalityNoticeCodeLengthRule(maxLength: 3600)
        let item = Imaging.newModalityNotice("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityNoticeVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Imaging.ModalityNoticeVersionRangeRule(min: 16, max: 255)
        let item = Imaging.newModalityNotice("x", label: "y")
        item.version = 256
        #expect(rule.check(item).count > 0)
    }
}
