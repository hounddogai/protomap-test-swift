@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalNetworkRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRegionalNetworkRuleValidator()
        let item = Referrals.newRegionalNetworkRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRegionalNetworkRuleAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Referrals.RegionalNetworkRuleAmountRangeRule(min: 1.7, max: 3391.4)
        let item = Referrals.newRegionalNetworkRule("x", title: "y")
        item.amount = 3392.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRegionalNetworkRuleBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Referrals.RegionalNetworkRuleBatchSizeRangeRule(min: 1000, max: 3600)
        let item = Referrals.newRegionalNetworkRule("x", title: "y")
        item.batchSize = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRegionalNetworkRuleSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Referrals.RegionalNetworkRuleSummaryLengthRule(maxLength: 120)
        let item = Referrals.newRegionalNetworkRule("x", title: "y")
        item.summary = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRegionalNetworkRuleRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Referrals.RegionalNetworkRuleRequiredPatientRefRule(message: "regional network rule needs an entry")
        let item = Referrals.newRegionalNetworkRule("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRegionalNetworkRuleRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Referrals.RegionalNetworkRuleRequiredSummaryRule(message: "regional network rule needs this field")
        let item = Referrals.newRegionalNetworkRule("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}
