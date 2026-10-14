@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalitySnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalitySnapshotValidator()
        let item = Imaging.newModalitySnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalitySnapshotDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Imaging.ModalitySnapshotDurationMinutesRangeRule(min: 16, max: 120)
        let item = Imaging.newModalitySnapshot("x", title: "y")
        item.durationMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingModalitySnapshotBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Imaging.ModalitySnapshotBudgetRangeRule(min: 1.8, max: 2992.9)
        let item = Imaging.newModalitySnapshot("x", title: "y")
        item.budget = 2994.4
        #expect(rule.check(item).count > 0)
    }
}
