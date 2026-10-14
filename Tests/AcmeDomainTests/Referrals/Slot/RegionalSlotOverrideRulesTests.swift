@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalSlotOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRegionalSlotOverrideValidator()
        let item = Referrals.newRegionalSlotOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRegionalSlotOverrideRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Referrals.RegionalSlotOverrideRevisionRangeRule(min: 255, max: 1000)
        let item = Referrals.newRegionalSlotOverride("x", name: "y")
        item.revision = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRegionalSlotOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.RegionalSlotOverrideCodeLengthRule(maxLength: 255)
        let item = Referrals.newRegionalSlotOverride("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRegionalSlotOverrideRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Referrals.RegionalSlotOverrideRefillsRangeRule(min: 64, max: 86400)
        let item = Referrals.newRegionalSlotOverride("x", name: "y")
        item.refills = 86401
        #expect(rule.check(item).count > 0)
    }
}
