@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityPolicyValidator()
        let item = Referrals.newEligibilityPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityPolicyThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Referrals.EligibilityPolicyThresholdRangeRule(min: 9.8, max: 2316.0)
        let item = Referrals.newEligibilityPolicy("x", name: "y")
        item.threshold = 2317.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsEligibilityPolicyRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.EligibilityPolicyRequiredNameRule(message: "eligibility policy needs a value")
        let item = Referrals.newEligibilityPolicy("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityPolicyOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Referrals.EligibilityPolicyOwnerIDLengthRule(maxLength: 255)
        let item = Referrals.newEligibilityPolicy("x", name: "y")
        item.ownerID = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.EligibilityPolicyCodeLengthRule(maxLength: 255)
        let item = Referrals.newEligibilityPolicy("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.EligibilityPolicyRequiredCodeRule(message: "eligibility policy needs this field")
        let item = Referrals.newEligibilityPolicy("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityPolicyNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.EligibilityPolicyNameLengthRule(maxLength: 86400)
        let item = Referrals.newEligibilityPolicy("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
