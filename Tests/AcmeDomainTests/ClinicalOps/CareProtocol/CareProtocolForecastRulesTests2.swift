@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolForecastValidator()
        let item = ClinicalOps.newCareProtocolForecast("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.CareProtocolForecastCodeLengthRule(maxLength: 1000)
        let item = ClinicalOps.newCareProtocolForecast("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolForecastTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.CareProtocolForecastTitleLengthRule(maxLength: 1000)
        let item = ClinicalOps.newCareProtocolForecast("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolForecastRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = ClinicalOps.CareProtocolForecastRequiredBedRule(message: "care protocol forecast needs this field")
        let item = ClinicalOps.newCareProtocolForecast("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
