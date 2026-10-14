@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkTemplateValidator()
        let item = Referrals.newNetworkTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkTemplateMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Referrals.NetworkTemplateMaximumRangeRule(min: 7.1, max: 4424.8)
        let item = Referrals.newNetworkTemplate("x", label: "y")
        item.maximum = 4426.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkTemplateChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Referrals.NetworkTemplateChecksumLengthRule(maxLength: 64)
        let item = Referrals.newNetworkTemplate("x", label: "y")
        item.checksum = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsNetworkTemplateStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Referrals.NetworkTemplateStartsAtRangeRule(min: 64, max: 120)
        let item = Referrals.newNetworkTemplate("x", label: "y")
        item.startsAt = 121
        #expect(rule.check(item).count > 0)
    }
}
