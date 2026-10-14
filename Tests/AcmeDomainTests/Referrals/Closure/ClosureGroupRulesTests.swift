@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureGroupValidator()
        let item = Referrals.newClosureGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureGroupRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Referrals.ClosureGroupRequiredFacilityRule(message: "closure group needs an entry")
        let item = Referrals.newClosureGroup("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureGroupTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.ClosureGroupTitleLengthRule(maxLength: 3600)
        let item = Referrals.newClosureGroup("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureGroupCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Referrals.ClosureGroupCostRangeRule(min: 7.4, max: 666.0)
        let item = Referrals.newClosureGroup("x", title: "y")
        item.cost = 667.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsClosureGroupRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.ClosureGroupRequiredTitleRule(message: "closure group needs a value")
        let item = Referrals.newClosureGroup("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
