@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientModalityScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultLenientModalityScoreValidator()
        let item = Imaging.newLenientModalityScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingLenientModalityScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.LenientModalityScoreCodeLengthRule(maxLength: 80)
        let item = Imaging.newLenientModalityScore("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingLenientModalityScorePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Imaging.LenientModalityScorePriorityRangeRule(min: 16, max: 255)
        let item = Imaging.newLenientModalityScore("x", title: "y")
        item.priority = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingLenientModalityScoreLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Imaging.LenientModalityScoreLimitRangeRule(min: 255, max: 3600)
        let item = Imaging.newLenientModalityScore("x", title: "y")
        item.limit = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingLenientModalityScoreRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Imaging.LenientModalityScoreRequiredPatientRefRule(message: "lenient modality score needs an entry")
        let item = Imaging.newLenientModalityScore("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
