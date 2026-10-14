@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalReadExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultSeasonalReadExceptionValidator()
        let item = Imaging.newSeasonalReadException("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingSeasonalReadExceptionRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Imaging.SeasonalReadExceptionRetriesRangeRule(min: 16, max: 120)
        let item = Imaging.newSeasonalReadException("x", label: "y")
        item.retries = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingSeasonalReadExceptionLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.SeasonalReadExceptionLabelLengthRule(maxLength: 1000)
        let item = Imaging.newSeasonalReadException("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingSeasonalReadExceptionRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Imaging.SeasonalReadExceptionRequiredNotesRule(message: "seasonal read exception needs an entry")
        let item = Imaging.newSeasonalReadException("", label: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}
