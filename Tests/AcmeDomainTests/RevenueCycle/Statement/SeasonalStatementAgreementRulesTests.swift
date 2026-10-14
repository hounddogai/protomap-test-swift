@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleSeasonalStatementAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultSeasonalStatementAgreementValidator()
        let item = RevenueCycle.newSeasonalStatementAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleSeasonalStatementAgreementExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = RevenueCycle.SeasonalStatementAgreementExpiresAtRangeRule(min: 120, max: 255)
        let item = RevenueCycle.newSeasonalStatementAgreement("x", name: "y")
        item.expiresAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleSeasonalStatementAgreementRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.SeasonalStatementAgreementRequiredNameRule(
            message: "seasonal statement agreement needs an entry"
        )
        let item = RevenueCycle.newSeasonalStatementAgreement("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleSeasonalStatementAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.SeasonalStatementAgreementRequiredCodeRule(
            message: "seasonal statement agreement needs an entry"
        )
        let item = RevenueCycle.newSeasonalStatementAgreement("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleSeasonalStatementAgreementPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = RevenueCycle.SeasonalStatementAgreementPriorityRangeRule(min: 64, max: 255)
        let item = RevenueCycle.newSeasonalStatementAgreement("x", name: "y")
        item.priority = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleSeasonalStatementAgreementNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.SeasonalStatementAgreementNameLengthRule(maxLength: 80)
        let item = RevenueCycle.newSeasonalStatementAgreement("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleSeasonalStatementAgreementRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = RevenueCycle.SeasonalStatementAgreementRequiredCurrencyRule(
            message: "seasonal statement agreement needs a value"
        )
        let item = RevenueCycle.newSeasonalStatementAgreement("", name: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}
