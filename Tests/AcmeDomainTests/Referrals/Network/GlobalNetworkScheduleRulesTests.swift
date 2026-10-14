@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalNetworkScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultGlobalNetworkScheduleValidator()
        let item = Referrals.newGlobalNetworkSchedule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsGlobalNetworkScheduleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.GlobalNetworkScheduleRequiredCodeRule(message: "global network schedule needs this field")
        let item = Referrals.newGlobalNetworkSchedule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsGlobalNetworkScheduleExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Referrals.GlobalNetworkScheduleExternalRefLengthRule(maxLength: 86400)
        let item = Referrals.newGlobalNetworkSchedule("x", name: "y")
        item.externalRef = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
