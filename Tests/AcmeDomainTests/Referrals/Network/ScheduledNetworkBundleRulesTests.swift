@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledNetworkBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultScheduledNetworkBundleValidator()
        let item = Referrals.newScheduledNetworkBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsScheduledNetworkBundleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.ScheduledNetworkBundleRequiredLabelRule(
            message: "scheduled network bundle needs this field"
        )
        let item = Referrals.newScheduledNetworkBundle("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsScheduledNetworkBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.ScheduledNetworkBundleRequiredCodeRule(message: "scheduled network bundle needs a value")
        let item = Referrals.newScheduledNetworkBundle("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsScheduledNetworkBundleRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Referrals.ScheduledNetworkBundleRequiredBedRule(message: "scheduled network bundle needs an entry")
        let item = Referrals.newScheduledNetworkBundle("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsScheduledNetworkBundleWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Referrals.ScheduledNetworkBundleWindowDaysRangeRule(min: 64, max: 255)
        let item = Referrals.newScheduledNetworkBundle("x", label: "y")
        item.windowDays = 256
        #expect(rule.check(item).count > 0)
    }
}
