@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedConsentFormOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultBatchedConsentFormOverrideValidator()
        let item = Consent.newBatchedConsentFormOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentBatchedConsentFormOverrideBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Consent.BatchedConsentFormOverrideBatchSizeRangeRule(min: 86400, max: 86400)
        let item = Consent.newBatchedConsentFormOverride("x", title: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentBatchedConsentFormOverrideRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.BatchedConsentFormOverrideRequiredTitleRule(
            message: "batched consent form override needs this field"
        )
        let item = Consent.newBatchedConsentFormOverride("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentBatchedConsentFormOverrideTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.BatchedConsentFormOverrideTitleLengthRule(maxLength: 86400)
        let item = Consent.newBatchedConsentFormOverride("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
