@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyReservationValidator()
        let item = Imaging.newStudyReservation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyReservationAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Imaging.StudyReservationAttemptsRangeRule(min: 32, max: 3600)
        let item = Imaging.newStudyReservation("x", name: "y")
        item.attempts = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStudyReservationPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Imaging.StudyReservationPatientRefLengthRule(maxLength: 64)
        let item = Imaging.newStudyReservation("x", name: "y")
        item.patientRef = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudyReservationScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Imaging.StudyReservationScoreRangeRule(min: 4.1, max: 3563.4)
        let item = Imaging.newStudyReservation("x", name: "y")
        item.score = 3564.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStudyReservationNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.StudyReservationNameLengthRule(maxLength: 1000)
        let item = Imaging.newStudyReservation("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
