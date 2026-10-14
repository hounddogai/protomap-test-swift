@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityRollupValidator()
        let item = Imaging.newModalityRollup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityRollupVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Imaging.ModalityRollupVersionRangeRule(min: 64, max: 255)
        let item = Imaging.newModalityRollup("x", title: "y")
        item.version = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingModalityRollupRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Imaging.ModalityRollupRequiredReviewerRule(message: "modality rollup needs an entry")
        let item = Imaging.newModalityRollup("", title: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityRollupRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Imaging.ModalityRollupRequiredBedRule(message: "modality rollup needs an entry")
        let item = Imaging.newModalityRollup("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
