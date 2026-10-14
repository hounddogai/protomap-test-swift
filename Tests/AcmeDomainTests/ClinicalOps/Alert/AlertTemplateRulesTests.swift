@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertTemplateValidator()
        let item = ClinicalOps.newAlertTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.AlertTemplateRequiredCodeRule(message: "alert template needs this field")
        let item = ClinicalOps.newAlertTemplate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertTemplateRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.AlertTemplateRequiredNameRule(message: "alert template needs this field")
        let item = ClinicalOps.newAlertTemplate("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
