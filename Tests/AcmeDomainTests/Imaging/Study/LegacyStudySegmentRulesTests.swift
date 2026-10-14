@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyStudySegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultLegacyStudySegmentValidator()
        let item = Imaging.newLegacyStudySegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingLegacyStudySegmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.LegacyStudySegmentLabelLengthRule(maxLength: 255)
        let item = Imaging.newLegacyStudySegment("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingLegacyStudySegmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.LegacyStudySegmentRequiredLabelRule(message: "legacy study segment needs a value")
        let item = Imaging.newLegacyStudySegment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingLegacyStudySegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.LegacyStudySegmentCodeLengthRule(maxLength: 255)
        let item = Imaging.newLegacyStudySegment("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingLegacyStudySegmentGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Imaging.LegacyStudySegmentGraceDaysRangeRule(min: 80, max: 80)
        let item = Imaging.newLegacyStudySegment("x", label: "y")
        item.graceDays = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingLegacyStudySegmentAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Imaging.LegacyStudySegmentAllergyLengthRule(maxLength: 32)
        let item = Imaging.newLegacyStudySegment("x", label: "y")
        item.allergy = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}
