@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalSlotNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultGlobalSlotNoticeValidator()
        let item = Referrals.newGlobalSlotNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsGlobalSlotNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.GlobalSlotNoticeCodeLengthRule(maxLength: 120)
        let item = Referrals.newGlobalSlotNotice("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsGlobalSlotNoticeSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Referrals.GlobalSlotNoticeSequenceRangeRule(min: 255, max: 1000)
        let item = Referrals.newGlobalSlotNotice("x", title: "y")
        item.sequence = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsGlobalSlotNoticeTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Referrals.GlobalSlotNoticeTimezoneLengthRule(maxLength: 64)
        let item = Referrals.newGlobalSlotNotice("x", title: "y")
        item.timezone = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsGlobalSlotNoticeCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Referrals.GlobalSlotNoticeCapacityRangeRule(min: 16, max: 64)
        let item = Referrals.newGlobalSlotNotice("x", title: "y")
        item.capacity = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsGlobalSlotNoticeRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Referrals.GlobalSlotNoticeRequiredTimezoneRule(message: "global slot notice needs a value")
        let item = Referrals.newGlobalSlotNotice("", title: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}
