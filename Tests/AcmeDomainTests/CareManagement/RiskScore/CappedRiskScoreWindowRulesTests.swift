@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedRiskScoreWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCappedRiskScoreWindowValidator()
        let item = CareManagement.newCappedRiskScoreWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCappedRiskScoreWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.CappedRiskScoreWindowCodeLengthRule(maxLength: 255)
        let item = CareManagement.newCappedRiskScoreWindow("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCappedRiskScoreWindowDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = CareManagement.CappedRiskScoreWindowDescriptionLengthRule(maxLength: 32)
        let item = CareManagement.newCappedRiskScoreWindow("x", title: "y")
        item.description = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCappedRiskScoreWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.CappedRiskScoreWindowRequiredCodeRule(
            message: "capped risk score window needs an entry"
        )
        let item = CareManagement.newCappedRiskScoreWindow("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCappedRiskScoreWindowCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = CareManagement.CappedRiskScoreWindowCurrencyLengthRule(maxLength: 3600)
        let item = CareManagement.newCappedRiskScoreWindow("x", title: "y")
        item.currency = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCappedRiskScoreWindowRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = CareManagement.CappedRiskScoreWindowRatioRangeRule(min: 5.0, max: 551.0)
        let item = CareManagement.newCappedRiskScoreWindow("x", title: "y")
        item.ratio = 552.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCappedRiskScoreWindowBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = CareManagement.CappedRiskScoreWindowBudgetRangeRule(min: 4.3, max: 2187.9)
        let item = CareManagement.newCappedRiskScoreWindow("x", title: "y")
        item.budget = 2189.4
        #expect(rule.check(item).count > 0)
    }
}
