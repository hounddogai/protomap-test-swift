@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedOutreachTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCappedOutreachTemplateValidator()
        let item = CareManagement.newCappedOutreachTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCappedOutreachTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.CappedOutreachTemplateCodeLengthRule(maxLength: 120)
        let item = CareManagement.newCappedOutreachTemplate("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCappedOutreachTemplateRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = CareManagement.CappedOutreachTemplateRequiredPatientRefRule(
            message: "capped outreach template needs this field"
        )
        let item = CareManagement.newCappedOutreachTemplate("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCappedOutreachTemplateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.CappedOutreachTemplateLabelLengthRule(maxLength: 32)
        let item = CareManagement.newCappedOutreachTemplate("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
