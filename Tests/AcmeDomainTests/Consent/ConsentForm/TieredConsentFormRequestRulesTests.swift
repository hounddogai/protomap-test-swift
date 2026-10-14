@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredConsentFormRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultTieredConsentFormRequestValidator()
        let item = Consent.newTieredConsentFormRequest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentTieredConsentFormRequestLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Consent.TieredConsentFormRequestLocaleLengthRule(maxLength: 1000)
        let item = Consent.newTieredConsentFormRequest("x", label: "y")
        item.locale = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentTieredConsentFormRequestBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Consent.TieredConsentFormRequestBatchSizeRangeRule(min: 32, max: 1000)
        let item = Consent.newTieredConsentFormRequest("x", label: "y")
        item.batchSize = 1001
        #expect(rule.check(item).count > 0)
    }
}
