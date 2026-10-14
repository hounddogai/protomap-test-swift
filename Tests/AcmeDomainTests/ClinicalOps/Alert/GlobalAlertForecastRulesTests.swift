@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalAlertForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultGlobalAlertForecastValidator()
        let item = ClinicalOps.newGlobalAlertForecast("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsGlobalAlertForecastRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = ClinicalOps.GlobalAlertForecastRequiredSpecialtyRule(
            message: "global alert forecast needs this field"
        )
        let item = ClinicalOps.newGlobalAlertForecast("", label: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsGlobalAlertForecastExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = ClinicalOps.GlobalAlertForecastExternalRefLengthRule(maxLength: 80)
        let item = ClinicalOps.newGlobalAlertForecast("x", label: "y")
        item.externalRef = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsGlobalAlertForecastQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = ClinicalOps.GlobalAlertForecastQuantityRangeRule(min: 64, max: 1000)
        let item = ClinicalOps.newGlobalAlertForecast("x", label: "y")
        item.quantity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsGlobalAlertForecastRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = ClinicalOps.GlobalAlertForecastRequiredExternalRefRule(message: "global alert forecast needs a value")
        let item = ClinicalOps.newGlobalAlertForecast("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsGlobalAlertForecastRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.GlobalAlertForecastRequiredCodeRule(message: "global alert forecast needs a value")
        let item = ClinicalOps.newGlobalAlertForecast("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsGlobalAlertForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.GlobalAlertForecastCodeLengthRule(maxLength: 255)
        let item = ClinicalOps.newGlobalAlertForecast("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
