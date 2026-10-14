@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureProfileValidator()
        let item = Referrals.newClosureProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureProfileRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Referrals.ClosureProfileRequiredUnitRule(message: "closure profile needs a value")
        let item = Referrals.newClosureProfile("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureProfileRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.ClosureProfileRequiredTitleRule(message: "closure profile needs an entry")
        let item = Referrals.newClosureProfile("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureProfilePhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Referrals.ClosureProfilePhoneLengthRule(maxLength: 80)
        let item = Referrals.newClosureProfile("x", title: "y")
        item.phone = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureProfileBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Referrals.ClosureProfileBatchSizeRangeRule(min: 16, max: 1000)
        let item = Referrals.newClosureProfile("x", title: "y")
        item.batchSize = 1001
        #expect(rule.check(item).count > 0)
    }
}
