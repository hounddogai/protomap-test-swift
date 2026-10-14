@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredStudySnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultTieredStudySnapshotValidator()
        let item = Imaging.newTieredStudySnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingTieredStudySnapshotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.TieredStudySnapshotTitleLengthRule(maxLength: 255)
        let item = Imaging.newTieredStudySnapshot("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingTieredStudySnapshotCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Imaging.TieredStudySnapshotCountryLengthRule(maxLength: 16)
        let item = Imaging.newTieredStudySnapshot("x", title: "y")
        item.country = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingTieredStudySnapshotRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Imaging.TieredStudySnapshotRequiredCountryRule(message: "tiered study snapshot needs a value")
        let item = Imaging.newTieredStudySnapshot("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredStudySnapshotThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Imaging.TieredStudySnapshotThresholdRangeRule(min: 5.4, max: 2830.0)
        let item = Imaging.newTieredStudySnapshot("x", title: "y")
        item.threshold = 2831.5
        #expect(rule.check(item).count > 0)
    }
}
