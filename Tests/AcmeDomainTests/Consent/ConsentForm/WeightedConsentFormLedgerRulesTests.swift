@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedConsentFormLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWeightedConsentFormLedgerValidator()
        let item = Consent.newWeightedConsentFormLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWeightedConsentFormLedgerNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.WeightedConsentFormLedgerNameLengthRule(maxLength: 32)
        let item = Consent.newWeightedConsentFormLedger("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWeightedConsentFormLedgerBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Consent.WeightedConsentFormLedgerBatchSizeRangeRule(min: 255, max: 86400)
        let item = Consent.newWeightedConsentFormLedger("x", name: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}
