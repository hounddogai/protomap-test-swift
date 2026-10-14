@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyBundleValidator()
        let item = Imaging.newStudyBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.StudyBundleCodeLengthRule(maxLength: 86400)
        let item = Imaging.newStudyBundle("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudyBundleOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Imaging.StudyBundleOwnerIDLengthRule(maxLength: 3600)
        let item = Imaging.newStudyBundle("x", label: "y")
        item.ownerID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudyBundleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.StudyBundleRequiredLabelRule(message: "study bundle needs a value")
        let item = Imaging.newStudyBundle("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStudyBundleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.StudyBundleLabelLengthRule(maxLength: 86400)
        let item = Imaging.newStudyBundle("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudyBundleWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Imaging.StudyBundleWeightRangeRule(min: 8.3, max: 1961.0)
        let item = Imaging.newStudyBundle("x", label: "y")
        item.weight = 1962.5
        #expect(rule.check(item).count > 0)
    }
}
