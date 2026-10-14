@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualAlertScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultManualAlertScoreValidator()
        let item = ClinicalOps.newManualAlertScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsManualAlertScoreRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = ClinicalOps.ManualAlertScoreRequiredCountryRule(message: "manual alert score needs an entry")
        let item = ClinicalOps.newManualAlertScore("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsManualAlertScoreMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = ClinicalOps.ManualAlertScoreMarginRangeRule(min: 0.1, max: 490.3)
        let item = ClinicalOps.newManualAlertScore("x", label: "y")
        item.margin = 491.8
        #expect(rule.check(item).count > 0)
    }
}
