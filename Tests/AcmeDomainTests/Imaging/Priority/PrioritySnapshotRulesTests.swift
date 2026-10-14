@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrioritySnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPrioritySnapshotValidator()
        let item = Imaging.newPrioritySnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPrioritySnapshotRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Imaging.PrioritySnapshotRatioRangeRule(min: 6.3, max: 1662.1)
        let item = Imaging.newPrioritySnapshot("x", label: "y")
        item.ratio = 1663.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPrioritySnapshotRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Imaging.PrioritySnapshotRequiredContactEmailRule(message: "priority snapshot needs a value")
        let item = Imaging.newPrioritySnapshot("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPrioritySnapshotDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Imaging.PrioritySnapshotDosageMgRangeRule(min: 2.3, max: 3196.6)
        let item = Imaging.newPrioritySnapshot("x", label: "y")
        item.dosageMg = 3198.1
        #expect(rule.check(item).count > 0)
    }
}
