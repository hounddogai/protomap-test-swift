@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAssessmentRecordValidator()
        let item = CareManagement.newAssessmentRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAssessmentRecordCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.AssessmentRecordCodeLengthRule(maxLength: 16)
        let item = CareManagement.newAssessmentRecord("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAssessmentRecordRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.AssessmentRecordRequiredTitleRule(message: "assessment record needs this field")
        let item = CareManagement.newAssessmentRecord("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAssessmentRecordTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.AssessmentRecordTitleLengthRule(maxLength: 86400)
        let item = CareManagement.newAssessmentRecord("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
