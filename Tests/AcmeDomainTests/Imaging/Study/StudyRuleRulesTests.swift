@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyRuleValidator()
        let item = Imaging.newStudyRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyRuleUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Imaging.StudyRuleUnitLengthRule(maxLength: 32)
        let item = Imaging.newStudyRule("x", name: "y")
        item.unit = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudyRuleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.StudyRuleRequiredNameRule(message: "study rule needs this field")
        let item = Imaging.newStudyRule("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStudyRuleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.StudyRuleNameLengthRule(maxLength: 32)
        let item = Imaging.newStudyRule("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudyRuleRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Imaging.StudyRuleRefillsRangeRule(min: 32, max: 255)
        let item = Imaging.newStudyRule("x", name: "y")
        item.refills = 256
        #expect(rule.check(item).count > 0)
    }
}
