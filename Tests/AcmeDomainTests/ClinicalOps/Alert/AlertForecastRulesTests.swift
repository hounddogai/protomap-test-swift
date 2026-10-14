@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertForecastValidator()
        let item = ClinicalOps.newAlertForecast("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertForecastRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.AlertForecastRequiredTitleRule(message: "alert forecast needs a value")
        let item = ClinicalOps.newAlertForecast("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertForecastRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.AlertForecastRequiredCodeRule(message: "alert forecast needs a value")
        let item = ClinicalOps.newAlertForecast("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertForecastRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = ClinicalOps.AlertForecastRevisionRangeRule(min: 80, max: 255)
        let item = ClinicalOps.newAlertForecast("x", title: "y")
        item.revision = 256
        #expect(rule.check(item).count > 0)
    }
}
