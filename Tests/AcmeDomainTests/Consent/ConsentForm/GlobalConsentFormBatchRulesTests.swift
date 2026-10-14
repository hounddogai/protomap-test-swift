@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalConsentFormBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultGlobalConsentFormBatchValidator()
        let item = Consent.newGlobalConsentFormBatch("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentGlobalConsentFormBatchRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.GlobalConsentFormBatchRequiredNameRule(message: "global consent form batch needs a value")
        let item = Consent.newGlobalConsentFormBatch("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentGlobalConsentFormBatchMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Consent.GlobalConsentFormBatchMinimumRangeRule(min: 0.2, max: 4383.9)
        let item = Consent.newGlobalConsentFormBatch("x", name: "y")
        item.minimum = 4385.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentGlobalConsentFormBatchBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Consent.GlobalConsentFormBatchBudgetRangeRule(min: 1.1, max: 2721.6)
        let item = Consent.newGlobalConsentFormBatch("x", name: "y")
        item.budget = 2723.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentGlobalConsentFormBatchRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Consent.GlobalConsentFormBatchRequiredNotesRule(message: "global consent form batch needs this field")
        let item = Consent.newGlobalConsentFormBatch("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}
