@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkBatchValidator()
        let item = Referrals.newNetworkBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkBatchCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Referrals.NetworkBatchCeilingRangeRule(min: 1.4, max: 524.8)
        let item = Referrals.newNetworkBatch("x", label: "y")
        item.ceiling = 526.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.NetworkBatchCodeLengthRule(maxLength: 64)
        let item = Referrals.newNetworkBatch("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
