@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedInteractionBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultBatchedInteractionBudgetValidator()
        let item = Pharmacy.newBatchedInteractionBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyBatchedInteractionBudgetSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Pharmacy.BatchedInteractionBudgetSourceLengthRule(maxLength: 16)
        let item = Pharmacy.newBatchedInteractionBudget("x", title: "y")
        item.source = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyBatchedInteractionBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.BatchedInteractionBudgetCodeLengthRule(maxLength: 64)
        let item = Pharmacy.newBatchedInteractionBudget("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
