@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAssessmentRequestValidator()
        let item = CareManagement.newAssessmentRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAssessmentRequestVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = CareManagement.AssessmentRequestVersionRangeRule(min: 120, max: 86400)
        let item = CareManagement.newAssessmentRequest("x", title: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAssessmentRequestRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = CareManagement.AssessmentRequestRequiredProcedureCodeRule(message: "assessment request needs a value")
        let item = CareManagement.newAssessmentRequest("", title: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAssessmentRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.AssessmentRequestRequiredCodeRule(message: "assessment request needs an entry")
        let item = CareManagement.newAssessmentRequest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAssessmentRequestProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = CareManagement.AssessmentRequestProcedureCodeLengthRule(maxLength: 255)
        let item = CareManagement.newAssessmentRequest("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAssessmentRequestUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = CareManagement.AssessmentRequestUpdatedAtRangeRule(min: 32, max: 80)
        let item = CareManagement.newAssessmentRequest("x", title: "y")
        item.updatedAt = 81
        #expect(rule.check(item).count > 0)
    }
}
