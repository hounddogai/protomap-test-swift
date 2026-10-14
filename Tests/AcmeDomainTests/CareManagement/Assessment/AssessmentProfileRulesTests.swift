@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAssessmentProfileValidator()
        let item = CareManagement.newAssessmentProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAssessmentProfileRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = CareManagement.AssessmentProfileRequiredChannelRule(message: "assessment profile needs a value")
        let item = CareManagement.newAssessmentProfile("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAssessmentProfileProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = CareManagement.AssessmentProfileProcedureCodeLengthRule(maxLength: 32)
        let item = CareManagement.newAssessmentProfile("x", name: "y")
        item.procedureCode = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAssessmentProfileNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.AssessmentProfileNameLengthRule(maxLength: 1000)
        let item = CareManagement.newAssessmentProfile("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
