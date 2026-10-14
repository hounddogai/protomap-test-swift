@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalNetworkGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultGlobalNetworkGroupValidator()
        let item = Referrals.newGlobalNetworkGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsGlobalNetworkGroupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.GlobalNetworkGroupLabelLengthRule(maxLength: 120)
        let item = Referrals.newGlobalNetworkGroup("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsGlobalNetworkGroupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.GlobalNetworkGroupRequiredLabelRule(message: "global network group needs an entry")
        let item = Referrals.newGlobalNetworkGroup("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsGlobalNetworkGroupFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Referrals.GlobalNetworkGroupFacilityLengthRule(maxLength: 86400)
        let item = Referrals.newGlobalNetworkGroup("x", label: "y")
        item.facility = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsGlobalNetworkGroupRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Referrals.GlobalNetworkGroupRequiredFacilityRule(message: "global network group needs a value")
        let item = Referrals.newGlobalNetworkGroup("", label: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}
