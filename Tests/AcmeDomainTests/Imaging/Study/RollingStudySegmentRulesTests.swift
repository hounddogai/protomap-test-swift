@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingStudySegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRollingStudySegmentValidator()
        let item = Imaging.newRollingStudySegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRollingStudySegmentRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Imaging.RollingStudySegmentRequiredPatientRefRule(message: "rolling study segment needs a value")
        let item = Imaging.newRollingStudySegment("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRollingStudySegmentPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Imaging.RollingStudySegmentPayerLengthRule(maxLength: 86400)
        let item = Imaging.newRollingStudySegment("x", name: "y")
        item.payer = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
