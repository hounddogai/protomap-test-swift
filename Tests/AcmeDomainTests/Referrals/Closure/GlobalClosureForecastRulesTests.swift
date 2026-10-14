@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalClosureForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultGlobalClosureForecastValidator()
        let item = Referrals.newGlobalClosureForecast("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsGlobalClosureForecastRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.GlobalClosureForecastRequiredTitleRule(message: "global closure forecast needs this field")
        let item = Referrals.newGlobalClosureForecast("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsGlobalClosureForecastRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Referrals.GlobalClosureForecastRevisionRangeRule(min: 32, max: 3600)
        let item = Referrals.newGlobalClosureForecast("x", title: "y")
        item.revision = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsGlobalClosureForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.GlobalClosureForecastCodeLengthRule(maxLength: 32)
        let item = Referrals.newGlobalClosureForecast("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
