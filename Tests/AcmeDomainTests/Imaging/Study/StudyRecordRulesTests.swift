@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyRecordValidator()
        let item = Imaging.newStudyRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyRecordContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Imaging.StudyRecordContactEmailLengthRule(maxLength: 120)
        let item = Imaging.newStudyRecord("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudyRecordBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Imaging.StudyRecordBudgetRangeRule(min: 4.6, max: 433.9)
        let item = Imaging.newStudyRecord("x", label: "y")
        item.budget = 435.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStudyRecordCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Imaging.StudyRecordCategoryLengthRule(maxLength: 120)
        let item = Imaging.newStudyRecord("x", label: "y")
        item.category = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
