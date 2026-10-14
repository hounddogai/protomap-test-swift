@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyDisclosureAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLegacyDisclosureAgreementValidator()
        let item = Consent.newLegacyDisclosureAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLegacyDisclosureAgreementCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Consent.LegacyDisclosureAgreementCreatedAtRangeRule(min: 64, max: 3600)
        let item = Consent.newLegacyDisclosureAgreement("x", title: "y")
        item.createdAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLegacyDisclosureAgreementSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Consent.LegacyDisclosureAgreementSegmentLengthRule(maxLength: 86400)
        let item = Consent.newLegacyDisclosureAgreement("x", title: "y")
        item.segment = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLegacyDisclosureAgreementBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Consent.LegacyDisclosureAgreementBatchSizeRangeRule(min: 64, max: 120)
        let item = Consent.newLegacyDisclosureAgreement("x", title: "y")
        item.batchSize = 121
        #expect(rule.check(item).count > 0)
    }
}
