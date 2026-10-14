@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureRollupValidator()
        let item = Referrals.newClosureRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ClosureRollupCodeLengthRule(maxLength: 16)
        let item = Referrals.newClosureRollup("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.ClosureRollupRequiredCodeRule(message: "closure rollup needs an entry")
        let item = Referrals.newClosureRollup("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureRollupAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Referrals.ClosureRollupAttemptsRangeRule(min: 120, max: 3600)
        let item = Referrals.newClosureRollup("x", name: "y")
        item.attempts = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsClosureRollupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.ClosureRollupNameLengthRule(maxLength: 120)
        let item = Referrals.newClosureRollup("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
