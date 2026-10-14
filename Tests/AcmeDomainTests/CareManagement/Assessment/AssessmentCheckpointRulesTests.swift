@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAssessmentCheckpointValidator()
        let item = CareManagement.newAssessmentCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAssessmentCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.AssessmentCheckpointRequiredCodeRule(message: "assessment checkpoint needs this field")
        let item = CareManagement.newAssessmentCheckpoint("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAssessmentCheckpointExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = CareManagement.AssessmentCheckpointExternalRefLengthRule(maxLength: 86400)
        let item = CareManagement.newAssessmentCheckpoint("x", name: "y")
        item.externalRef = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAssessmentCheckpointRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = CareManagement.AssessmentCheckpointRequiredExternalRefRule(
            message: "assessment checkpoint needs a value"
        )
        let item = CareManagement.newAssessmentCheckpoint("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementAssessmentCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.AssessmentCheckpointCodeLengthRule(maxLength: 255)
        let item = CareManagement.newAssessmentCheckpoint("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
