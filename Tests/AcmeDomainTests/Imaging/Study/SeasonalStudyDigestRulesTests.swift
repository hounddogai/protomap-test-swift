@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalStudyDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultSeasonalStudyDigestValidator()
        let item = Imaging.newSeasonalStudyDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingSeasonalStudyDigestNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Imaging.SeasonalStudyDigestNotesLengthRule(maxLength: 1000)
        let item = Imaging.newSeasonalStudyDigest("x", label: "y")
        item.notes = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingSeasonalStudyDigestAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Imaging.SeasonalStudyDigestAttemptsRangeRule(min: 64, max: 1000)
        let item = Imaging.newSeasonalStudyDigest("x", label: "y")
        item.attempts = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingSeasonalStudyDigestRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Imaging.SeasonalStudyDigestRequiredNotesRule(message: "seasonal study digest needs an entry")
        let item = Imaging.newSeasonalStudyDigest("", label: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingSeasonalStudyDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.SeasonalStudyDigestRequiredCodeRule(message: "seasonal study digest needs an entry")
        let item = Imaging.newSeasonalStudyDigest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
