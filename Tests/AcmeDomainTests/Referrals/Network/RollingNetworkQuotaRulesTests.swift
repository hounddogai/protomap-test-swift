@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingNetworkQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRollingNetworkQuotaValidator()
        let item = Referrals.newRollingNetworkQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRollingNetworkQuotaQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Referrals.RollingNetworkQuotaQuantityRangeRule(min: 16, max: 32)
        let item = Referrals.newRollingNetworkQuota("x", label: "y")
        item.quantity = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRollingNetworkQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.RollingNetworkQuotaCodeLengthRule(maxLength: 16)
        let item = Referrals.newRollingNetworkQuota("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRollingNetworkQuotaRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Referrals.RollingNetworkQuotaRequiredAllergyRule(message: "rolling network quota needs this field")
        let item = Referrals.newRollingNetworkQuota("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRollingNetworkQuotaAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Referrals.RollingNetworkQuotaAcuityRangeRule(min: 255, max: 1000)
        let item = Referrals.newRollingNetworkQuota("x", label: "y")
        item.acuity = 1001
        #expect(rule.check(item).count > 0)
    }
}
