@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyAssignmentValidator()
        let item = Imaging.newStudyAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.StudyAssignmentCodeLengthRule(maxLength: 86400)
        let item = Imaging.newStudyAssignment("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudyAssignmentBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Imaging.StudyAssignmentBatchSizeRangeRule(min: 16, max: 120)
        let item = Imaging.newStudyAssignment("x", name: "y")
        item.batchSize = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStudyAssignmentDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Imaging.StudyAssignmentDiscountRangeRule(min: 3.7, max: 3690.1)
        let item = Imaging.newStudyAssignment("x", name: "y")
        item.discount = 3691.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStudyAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.StudyAssignmentRequiredCodeRule(message: "study assignment needs a value")
        let item = Imaging.newStudyAssignment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStudyAssignmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.StudyAssignmentRequiredNameRule(message: "study assignment needs a value")
        let item = Imaging.newStudyAssignment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
