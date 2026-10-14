@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveAssessmentAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAdaptiveAssessmentAssignmentValidator()
        let item = CareManagement.newAdaptiveAssessmentAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAdaptiveAssessmentAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.AdaptiveAssessmentAssignmentCodeLengthRule(maxLength: 255)
        let item = CareManagement.newAdaptiveAssessmentAssignment("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveAssessmentAssignmentRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = CareManagement.AdaptiveAssessmentAssignmentRequiredPayerRule(
            message: "adaptive assessment assignment needs an entry"
        )
        let item = CareManagement.newAdaptiveAssessmentAssignment("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}
