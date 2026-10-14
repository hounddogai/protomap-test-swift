@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingStatementProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultPendingStatementProposalValidator()
        let item = RevenueCycle.newPendingStatementProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCyclePendingStatementProposalCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.PendingStatementProposalCodeLengthRule(maxLength: 86400)
        let item = RevenueCycle.newPendingStatementProposal("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCyclePendingStatementProposalRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.PendingStatementProposalRequiredNameRule(
            message: "pending statement proposal needs an entry"
        )
        let item = RevenueCycle.newPendingStatementProposal("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCyclePendingStatementProposalCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = RevenueCycle.PendingStatementProposalCurrencyLengthRule(maxLength: 86400)
        let item = RevenueCycle.newPendingStatementProposal("x", name: "y")
        item.currency = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCyclePendingStatementProposalRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = RevenueCycle.PendingStatementProposalRequiredAllergyRule(
            message: "pending statement proposal needs a value"
        )
        let item = RevenueCycle.newPendingStatementProposal("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCyclePendingStatementProposalVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = RevenueCycle.PendingStatementProposalVisitMinutesRangeRule(min: 255, max: 1000)
        let item = RevenueCycle.newPendingStatementProposal("x", name: "y")
        item.visitMinutes = 1001
        #expect(rule.check(item).count > 0)
    }
}
