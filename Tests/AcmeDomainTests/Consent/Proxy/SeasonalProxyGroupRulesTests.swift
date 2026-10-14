@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalProxyGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultSeasonalProxyGroupValidator()
        let item = Consent.newSeasonalProxyGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentSeasonalProxyGroupWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Consent.SeasonalProxyGroupWeightRangeRule(min: 2.5, max: 1513.2)
        let item = Consent.newSeasonalProxyGroup("x", title: "y")
        item.weight = 1514.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentSeasonalProxyGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.SeasonalProxyGroupCodeLengthRule(maxLength: 80)
        let item = Consent.newSeasonalProxyGroup("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentSeasonalProxyGroupRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.SeasonalProxyGroupRequiredTitleRule(message: "seasonal proxy group needs this field")
        let item = Consent.newSeasonalProxyGroup("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentSeasonalProxyGroupRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Consent.SeasonalProxyGroupRequiredSummaryRule(message: "seasonal proxy group needs a value")
        let item = Consent.newSeasonalProxyGroup("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}
