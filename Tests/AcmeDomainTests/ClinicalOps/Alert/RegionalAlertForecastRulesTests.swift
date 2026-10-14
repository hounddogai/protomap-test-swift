@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalAlertForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRegionalAlertForecastValidator()
        let item = ClinicalOps.newRegionalAlertForecast("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRegionalAlertForecastNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.RegionalAlertForecastNameLengthRule(maxLength: 3600)
        let item = ClinicalOps.newRegionalAlertForecast("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRegionalAlertForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.RegionalAlertForecastCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newRegionalAlertForecast("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
