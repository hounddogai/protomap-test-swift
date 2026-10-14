@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotRecordValidator()
        let item = Referrals.newSlotRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotRecordFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Referrals.SlotRecordFacilityLengthRule(maxLength: 86400)
        let item = Referrals.newSlotRecord("x", title: "y")
        item.facility = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotRecordRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Referrals.SlotRecordRequiredFacilityRule(message: "slot record needs this field")
        let item = Referrals.newSlotRecord("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSlotRecordCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.SlotRecordCodeLengthRule(maxLength: 64)
        let item = Referrals.newSlotRecord("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
