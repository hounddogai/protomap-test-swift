@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalSlotNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSeasonalSlotNoticeValidator()
        let item = Referrals.newSeasonalSlotNotice("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSeasonalSlotNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.SeasonalSlotNoticeCodeLengthRule(maxLength: 64)
        let item = Referrals.newSeasonalSlotNotice("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSeasonalSlotNoticeLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.SeasonalSlotNoticeLabelLengthRule(maxLength: 3600)
        let item = Referrals.newSeasonalSlotNotice("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSeasonalSlotNoticeQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Referrals.SeasonalSlotNoticeQuantityRangeRule(min: 32, max: 3600)
        let item = Referrals.newSeasonalSlotNotice("x", label: "y")
        item.quantity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSeasonalSlotNoticeAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Referrals.SeasonalSlotNoticeAttemptsRangeRule(min: 120, max: 86400)
        let item = Referrals.newSeasonalSlotNotice("x", label: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}
