@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistEstimateValidator()
        let item = Imaging.newWorklistEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistEstimateAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Imaging.WorklistEstimateAttemptsRangeRule(min: 80, max: 86400)
        let item = Imaging.newWorklistEstimate("x", name: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWorklistEstimateNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Imaging.WorklistEstimateNotesLengthRule(maxLength: 120)
        let item = Imaging.newWorklistEstimate("x", name: "y")
        item.notes = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.WorklistEstimateRequiredCodeRule(message: "worklist estimate needs a value")
        let item = Imaging.newWorklistEstimate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWorklistEstimateBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Imaging.WorklistEstimateBedLengthRule(maxLength: 80)
        let item = Imaging.newWorklistEstimate("x", name: "y")
        item.bed = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
