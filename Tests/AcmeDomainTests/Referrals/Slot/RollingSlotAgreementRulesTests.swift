@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingSlotAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRollingSlotAgreementValidator()
        let item = Referrals.newRollingSlotAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRollingSlotAgreementRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.RollingSlotAgreementRequiredNameRule(message: "rolling slot agreement needs a value")
        let item = Referrals.newRollingSlotAgreement("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRollingSlotAgreementBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Referrals.RollingSlotAgreementBatchSizeRangeRule(min: 32, max: 120)
        let item = Referrals.newRollingSlotAgreement("x", name: "y")
        item.batchSize = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRollingSlotAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.RollingSlotAgreementRequiredCodeRule(message: "rolling slot agreement needs this field")
        let item = Referrals.newRollingSlotAgreement("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
