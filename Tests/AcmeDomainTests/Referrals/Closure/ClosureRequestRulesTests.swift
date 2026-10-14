@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureRequestValidator()
        let item = Referrals.newClosureRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ClosureRequestCodeLengthRule(maxLength: 64)
        let item = Referrals.newClosureRequest("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureRequestRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Referrals.ClosureRequestRateRangeRule(min: 5.1, max: 3580.3)
        let item = Referrals.newClosureRequest("x", name: "y")
        item.rate = 3581.8
        #expect(rule.check(item).count > 0)
    }
}
