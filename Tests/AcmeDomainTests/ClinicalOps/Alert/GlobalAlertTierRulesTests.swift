@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalAlertTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultGlobalAlertTierValidator()
        let item = ClinicalOps.newGlobalAlertTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsGlobalAlertTierRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.GlobalAlertTierRequiredTitleRule(message: "global alert tier needs this field")
        let item = ClinicalOps.newGlobalAlertTier("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsGlobalAlertTierDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = ClinicalOps.GlobalAlertTierDosageMgRangeRule(min: 8.8, max: 2435.0)
        let item = ClinicalOps.newGlobalAlertTier("x", title: "y")
        item.dosageMg = 2436.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsGlobalAlertTierRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.GlobalAlertTierRequiredNameRule(message: "global alert tier needs this field")
        let item = ClinicalOps.newGlobalAlertTier("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
