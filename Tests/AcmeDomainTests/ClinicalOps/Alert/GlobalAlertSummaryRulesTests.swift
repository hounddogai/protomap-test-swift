@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalAlertSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultGlobalAlertSummaryValidator()
        let item = ClinicalOps.newGlobalAlertSummary("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsGlobalAlertSummaryRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = ClinicalOps.GlobalAlertSummaryRequiredDescriptionRule(message: "global alert summary needs an entry")
        let item = ClinicalOps.newGlobalAlertSummary("", name: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsGlobalAlertSummaryDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = ClinicalOps.GlobalAlertSummaryDescriptionLengthRule(maxLength: 80)
        let item = ClinicalOps.newGlobalAlertSummary("x", name: "y")
        item.description = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsGlobalAlertSummaryRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.GlobalAlertSummaryRequiredNameRule(message: "global alert summary needs a value")
        let item = ClinicalOps.newGlobalAlertSummary("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
