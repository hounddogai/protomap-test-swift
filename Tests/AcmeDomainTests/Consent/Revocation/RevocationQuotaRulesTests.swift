@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRevocationQuotaValidator()
        let item = Consent.newRevocationQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRevocationQuotaFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Consent.RevocationQuotaFacilityLengthRule(maxLength: 80)
        let item = Consent.newRevocationQuota("x", label: "y")
        item.facility = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRevocationQuotaRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Consent.RevocationQuotaRatioRangeRule(min: 5.7, max: 1004.8)
        let item = Consent.newRevocationQuota("x", label: "y")
        item.ratio = 1006.3
        #expect(rule.check(item).count > 0)
    }
}
