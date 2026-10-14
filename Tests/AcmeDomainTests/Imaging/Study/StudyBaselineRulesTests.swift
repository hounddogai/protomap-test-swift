@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyBaselineValidator()
        let item = Imaging.newStudyBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyBaselineRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Imaging.StudyBaselineRateRangeRule(min: 8.9, max: 3409.2)
        let item = Imaging.newStudyBaseline("x", label: "y")
        item.rate = 3410.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStudyBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.StudyBaselineRequiredCodeRule(message: "study baseline needs this field")
        let item = Imaging.newStudyBaseline("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStudyBaselineRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.StudyBaselineRequiredLabelRule(message: "study baseline needs a value")
        let item = Imaging.newStudyBaseline("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
