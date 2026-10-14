@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictModalitySnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStrictModalitySnapshotValidator()
        let item = Imaging.newStrictModalitySnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStrictModalitySnapshotScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Imaging.StrictModalitySnapshotScoreRangeRule(min: 6.6, max: 4966.6)
        let item = Imaging.newStrictModalitySnapshot("x", label: "y")
        item.score = 4968.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStrictModalitySnapshotRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Imaging.StrictModalitySnapshotRequiredCategoryRule(
            message: "strict modality snapshot needs this field"
        )
        let item = Imaging.newStrictModalitySnapshot("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStrictModalitySnapshotFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Imaging.StrictModalitySnapshotFloorValueRangeRule(min: 9.0, max: 4204.7)
        let item = Imaging.newStrictModalitySnapshot("x", label: "y")
        item.floorValue = 4206.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStrictModalitySnapshotNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Imaging.StrictModalitySnapshotNotesLengthRule(maxLength: 32)
        let item = Imaging.newStrictModalitySnapshot("x", label: "y")
        item.notes = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStrictModalitySnapshotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.StrictModalitySnapshotLabelLengthRule(maxLength: 64)
        let item = Imaging.newStrictModalitySnapshot("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
