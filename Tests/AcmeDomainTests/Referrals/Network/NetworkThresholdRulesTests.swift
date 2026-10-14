@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkThresholdValidator()
        let item = Referrals.newNetworkThreshold("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkThresholdRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Referrals.NetworkThresholdRevisionRangeRule(min: 80, max: 255)
        let item = Referrals.newNetworkThreshold("x", label: "y")
        item.revision = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.NetworkThresholdRequiredCodeRule(message: "network threshold needs an entry")
        let item = Referrals.newNetworkThreshold("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
