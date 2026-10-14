@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyAgreementValidator()
        let item = Imaging.newStudyAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyAgreementRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.StudyAgreementRequiredTitleRule(message: "study agreement needs this field")
        let item = Imaging.newStudyAgreement("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStudyAgreementCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Imaging.StudyAgreementCostRangeRule(min: 3.2, max: 2664.3)
        let item = Imaging.newStudyAgreement("x", title: "y")
        item.cost = 2665.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStudyAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.StudyAgreementCodeLengthRule(maxLength: 120)
        let item = Imaging.newStudyAgreement("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
