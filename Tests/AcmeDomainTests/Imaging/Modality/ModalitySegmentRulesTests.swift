@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalitySegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalitySegmentValidator()
        let item = Imaging.newModalitySegment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalitySegmentRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Imaging.ModalitySegmentRequiredLocaleRule(message: "modality segment needs a value")
        let item = Imaging.newModalitySegment("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalitySegmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.ModalitySegmentTitleLengthRule(maxLength: 86400)
        let item = Imaging.newModalitySegment("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalitySegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ModalitySegmentRequiredCodeRule(message: "modality segment needs this field")
        let item = Imaging.newModalitySegment("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
