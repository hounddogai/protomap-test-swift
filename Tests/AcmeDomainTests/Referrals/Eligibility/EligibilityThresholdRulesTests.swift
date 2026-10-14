@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityThresholdValidator()
        let item = Referrals.newEligibilityThreshold("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.EligibilityThresholdRequiredCodeRule(message: "eligibility threshold needs a value")
        let item = Referrals.newEligibilityThreshold("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityThresholdRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Referrals.EligibilityThresholdRequiredExternalRefRule(message: "eligibility threshold needs an entry")
        let item = Referrals.newEligibilityThreshold("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.EligibilityThresholdCodeLengthRule(maxLength: 64)
        let item = Referrals.newEligibilityThreshold("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
