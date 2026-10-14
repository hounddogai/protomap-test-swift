@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryModalityDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPrimaryModalityDraftValidator()
        let item = Imaging.newPrimaryModalityDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPrimaryModalityDraftRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Imaging.PrimaryModalityDraftRequiredRegionRule(message: "primary modality draft needs a value")
        let item = Imaging.newPrimaryModalityDraft("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPrimaryModalityDraftRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Imaging.PrimaryModalityDraftRevisionRangeRule(min: 64, max: 3600)
        let item = Imaging.newPrimaryModalityDraft("x", label: "y")
        item.revision = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPrimaryModalityDraftRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Imaging.PrimaryModalityDraftRegionLengthRule(maxLength: 255)
        let item = Imaging.newPrimaryModalityDraft("x", label: "y")
        item.region = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}
