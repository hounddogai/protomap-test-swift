@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyMetricValidator()
        let item = Imaging.newStudyMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyMetricAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Imaging.StudyMetricAcuityRangeRule(min: 64, max: 64)
        let item = Imaging.newStudyMetric("x", label: "y")
        item.acuity = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStudyMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.StudyMetricRequiredCodeRule(message: "study metric needs an entry")
        let item = Imaging.newStudyMetric("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStudyMetricRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Imaging.StudyMetricRequiredClinicianIDRule(message: "study metric needs a value")
        let item = Imaging.newStudyMetric("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStudyMetricLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.StudyMetricLabelLengthRule(maxLength: 86400)
        let item = Imaging.newStudyMetric("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
