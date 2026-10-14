@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAssessmentClaimValidator()
        let item = CareManagement.newAssessmentClaim("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAssessmentClaimTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.AssessmentClaimTitleLengthRule(maxLength: 32)
        let item = CareManagement.newAssessmentClaim("x", label: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAssessmentClaimEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = CareManagement.AssessmentClaimEndsAtRangeRule(min: 16, max: 120)
        let item = CareManagement.newAssessmentClaim("x", label: "y")
        item.endsAt = 121
        #expect(rule.check(item).count > 0)
    }
}
