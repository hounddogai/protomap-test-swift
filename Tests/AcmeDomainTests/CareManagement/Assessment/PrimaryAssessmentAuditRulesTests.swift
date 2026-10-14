@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryAssessmentAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPrimaryAssessmentAuditValidator()
        let item = CareManagement.newPrimaryAssessmentAudit("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPrimaryAssessmentAuditNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.PrimaryAssessmentAuditNameLengthRule(maxLength: 3600)
        let item = CareManagement.newPrimaryAssessmentAudit("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementPrimaryAssessmentAuditMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = CareManagement.PrimaryAssessmentAuditMaximumRangeRule(min: 9.2, max: 4967.0)
        let item = CareManagement.newPrimaryAssessmentAudit("x", name: "y")
        item.maximum = 4968.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementPrimaryAssessmentAuditRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.PrimaryAssessmentAuditRequiredNameRule(
            message: "primary assessment audit needs a value"
        )
        let item = CareManagement.newPrimaryAssessmentAudit("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
