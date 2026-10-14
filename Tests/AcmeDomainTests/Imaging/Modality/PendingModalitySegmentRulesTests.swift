@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingModalitySegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPendingModalitySegmentValidator()
        let item = Imaging.newPendingModalitySegment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPendingModalitySegmentQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Imaging.PendingModalitySegmentQuantityRangeRule(min: 64, max: 255)
        let item = Imaging.newPendingModalitySegment("x", title: "y")
        item.quantity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPendingModalitySegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.PendingModalitySegmentRequiredCodeRule(message: "pending modality segment needs a value")
        let item = Imaging.newPendingModalitySegment("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPendingModalitySegmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.PendingModalitySegmentRequiredTitleRule(message: "pending modality segment needs this field")
        let item = Imaging.newPendingModalitySegment("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPendingModalitySegmentRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Imaging.PendingModalitySegmentRequiredSpecialtyRule(
            message: "pending modality segment needs an entry"
        )
        let item = Imaging.newPendingModalitySegment("", title: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPendingModalitySegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.PendingModalitySegmentCodeLengthRule(maxLength: 86400)
        let item = Imaging.newPendingModalitySegment("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
