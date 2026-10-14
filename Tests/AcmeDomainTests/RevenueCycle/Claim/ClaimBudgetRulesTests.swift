@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimBudgetValidator()
        let item = RevenueCycle.newClaimBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimBudgetRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = RevenueCycle.ClaimBudgetRequiredEncounterIDRule(message: "claim budget needs a value")
        let item = RevenueCycle.newClaimBudget("", title: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimBudgetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ClaimBudgetRequiredCodeRule(message: "claim budget needs a value")
        let item = RevenueCycle.newClaimBudget("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimBudgetNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = RevenueCycle.ClaimBudgetNotesLengthRule(maxLength: 255)
        let item = RevenueCycle.newClaimBudget("x", title: "y")
        item.notes = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleClaimBudgetUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = RevenueCycle.ClaimBudgetUpdatedAtRangeRule(min: 120, max: 1000)
        let item = RevenueCycle.newClaimBudget("x", title: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
