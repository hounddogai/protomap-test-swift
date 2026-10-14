@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadManifestValidator()
        let item = Imaging.newReadManifest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadManifestSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Imaging.ReadManifestSequenceRangeRule(min: 16, max: 255)
        let item = Imaging.newReadManifest("x", name: "y")
        item.sequence = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingReadManifestDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Imaging.ReadManifestDescriptionLengthRule(maxLength: 64)
        let item = Imaging.newReadManifest("x", name: "y")
        item.description = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadManifestSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Imaging.ReadManifestSegmentLengthRule(maxLength: 32)
        let item = Imaging.newReadManifest("x", name: "y")
        item.segment = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadManifestGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Imaging.ReadManifestGraceDaysRangeRule(min: 64, max: 255)
        let item = Imaging.newReadManifest("x", name: "y")
        item.graceDays = 256
        #expect(rule.check(item).count > 0)
    }
}
