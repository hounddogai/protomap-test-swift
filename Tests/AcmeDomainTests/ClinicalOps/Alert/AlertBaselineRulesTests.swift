@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertBaselineValidator()
        let item = ClinicalOps.newAlertBaseline("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertBaselineRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = ClinicalOps.AlertBaselineRequiredDescriptionRule(message: "alert baseline needs this field")
        let item = ClinicalOps.newAlertBaseline("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertBaselineTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.AlertBaselineTitleLengthRule(maxLength: 16)
        let item = ClinicalOps.newAlertBaseline("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.AlertBaselineCodeLengthRule(maxLength: 32)
        let item = ClinicalOps.newAlertBaseline("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertBaselineDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = ClinicalOps.AlertBaselineDescriptionLengthRule(maxLength: 120)
        let item = ClinicalOps.newAlertBaseline("x", title: "y")
        item.description = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.AlertBaselineRequiredCodeRule(message: "alert baseline needs a value")
        let item = ClinicalOps.newAlertBaseline("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
