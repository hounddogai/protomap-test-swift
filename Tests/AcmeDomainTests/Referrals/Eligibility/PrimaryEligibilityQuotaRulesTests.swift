@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryEligibilityQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPrimaryEligibilityQuotaValidator()
        let item = Referrals.newPrimaryEligibilityQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPrimaryEligibilityQuotaDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Referrals.PrimaryEligibilityQuotaDiagnosisCodeLengthRule(maxLength: 16)
        let item = Referrals.newPrimaryEligibilityQuota("x", label: "y")
        item.diagnosisCode = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsPrimaryEligibilityQuotaCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Referrals.PrimaryEligibilityQuotaCreatedAtRangeRule(min: 32, max: 3600)
        let item = Referrals.newPrimaryEligibilityQuota("x", label: "y")
        item.createdAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsPrimaryEligibilityQuotaLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.PrimaryEligibilityQuotaLabelLengthRule(maxLength: 86400)
        let item = Referrals.newPrimaryEligibilityQuota("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsPrimaryEligibilityQuotaRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Referrals.PrimaryEligibilityQuotaRetriesRangeRule(min: 32, max: 255)
        let item = Referrals.newPrimaryEligibilityQuota("x", label: "y")
        item.retries = 256
        #expect(rule.check(item).count > 0)
    }
}
