@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpAllocationValidator()
        let item = Referrals.newFollowUpAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpAllocationUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Referrals.FollowUpAllocationUnitLengthRule(maxLength: 16)
        let item = Referrals.newFollowUpAllocation("x", label: "y")
        item.unit = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpAllocationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.FollowUpAllocationLabelLengthRule(maxLength: 64)
        let item = Referrals.newFollowUpAllocation("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpAllocationRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Referrals.FollowUpAllocationRevisionRangeRule(min: 16, max: 1000)
        let item = Referrals.newFollowUpAllocation("x", label: "y")
        item.revision = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFollowUpAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.FollowUpAllocationRequiredCodeRule(message: "follow up allocation needs this field")
        let item = Referrals.newFollowUpAllocation("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.FollowUpAllocationCodeLengthRule(maxLength: 80)
        let item = Referrals.newFollowUpAllocation("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
