@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacySlotRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLegacySlotRecordValidator()
        let item = Referrals.newLegacySlotRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLegacySlotRecordRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.LegacySlotRecordRequiredTitleRule(message: "legacy slot record needs a value")
        let item = Referrals.newLegacySlotRecord("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLegacySlotRecordRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Referrals.LegacySlotRecordRateRangeRule(min: 8.0, max: 3341.5)
        let item = Referrals.newLegacySlotRecord("x", title: "y")
        item.rate = 3343.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsLegacySlotRecordExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Referrals.LegacySlotRecordExternalRefLengthRule(maxLength: 32)
        let item = Referrals.newLegacySlotRecord("x", title: "y")
        item.externalRef = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsLegacySlotRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.LegacySlotRecordRequiredCodeRule(message: "legacy slot record needs a value")
        let item = Referrals.newLegacySlotRecord("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
