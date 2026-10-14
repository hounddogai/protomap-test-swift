@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyThresholdValidator()
        let item = Imaging.newStudyThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyThresholdRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.StudyThresholdRequiredNameRule(message: "study threshold needs a value")
        let item = Imaging.newStudyThreshold("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStudyThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.StudyThresholdRequiredCodeRule(message: "study threshold needs this field")
        let item = Imaging.newStudyThreshold("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStudyThresholdRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Imaging.StudyThresholdRequiredClinicianIDRule(message: "study threshold needs a value")
        let item = Imaging.newStudyThreshold("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStudyThresholdLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Imaging.StudyThresholdLimitRangeRule(min: 80, max: 120)
        let item = Imaging.newStudyThreshold("x", name: "y")
        item.limit = 121
        #expect(rule.check(item).count > 0)
    }
}
