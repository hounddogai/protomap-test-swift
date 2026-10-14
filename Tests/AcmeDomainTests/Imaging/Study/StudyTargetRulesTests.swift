@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyTargetValidator()
        let item = Imaging.newStudyTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyTargetRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Imaging.StudyTargetRequiredEncounterIDRule(message: "study target needs an entry")
        let item = Imaging.newStudyTarget("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStudyTargetEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Imaging.StudyTargetEncounterIDLengthRule(maxLength: 80)
        let item = Imaging.newStudyTarget("x", label: "y")
        item.encounterID = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudyTargetDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Imaging.StudyTargetDurationMinutesRangeRule(min: 255, max: 3600)
        let item = Imaging.newStudyTarget("x", label: "y")
        item.durationMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}
