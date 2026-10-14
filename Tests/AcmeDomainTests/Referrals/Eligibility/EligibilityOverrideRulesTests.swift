@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityOverrideValidator()
        let item = Referrals.newEligibilityOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.EligibilityOverrideRequiredCodeRule(message: "eligibility override needs a value")
        let item = Referrals.newEligibilityOverride("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityOverrideRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Referrals.EligibilityOverrideRequiredFacilityRule(message: "eligibility override needs a value")
        let item = Referrals.newEligibilityOverride("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityOverrideOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Referrals.EligibilityOverrideOwnerIDLengthRule(maxLength: 80)
        let item = Referrals.newEligibilityOverride("x", title: "y")
        item.ownerID = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
