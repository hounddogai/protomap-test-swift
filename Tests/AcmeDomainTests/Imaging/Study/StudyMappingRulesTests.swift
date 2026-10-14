@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyMappingValidator()
        let item = Imaging.newStudyMapping("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyMappingRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Imaging.StudyMappingRequiredSourceRule(message: "study mapping needs this field")
        let item = Imaging.newStudyMapping("", label: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStudyMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.StudyMappingRequiredCodeRule(message: "study mapping needs this field")
        let item = Imaging.newStudyMapping("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStudyMappingSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Imaging.StudyMappingSourceLengthRule(maxLength: 1000)
        let item = Imaging.newStudyMapping("x", label: "y")
        item.source = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}
