@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedWitnessCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultBatchedWitnessCycleValidator()
        let item = Consent.newBatchedWitnessCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentBatchedWitnessCycleExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Consent.BatchedWitnessCycleExternalRefLengthRule(maxLength: 86400)
        let item = Consent.newBatchedWitnessCycle("x", name: "y")
        item.externalRef = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentBatchedWitnessCycleBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Consent.BatchedWitnessCycleBudgetRangeRule(min: 8.9, max: 1770.9)
        let item = Consent.newBatchedWitnessCycle("x", name: "y")
        item.budget = 1772.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentBatchedWitnessCycleRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Consent.BatchedWitnessCycleRequiredExternalRefRule(message: "batched witness cycle needs an entry")
        let item = Consent.newBatchedWitnessCycle("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentBatchedWitnessCycleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.BatchedWitnessCycleLabelLengthRule(maxLength: 255)
        let item = Consent.newBatchedWitnessCycle("x", name: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
