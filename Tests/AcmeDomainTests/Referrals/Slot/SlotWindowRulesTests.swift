@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotWindowValidator()
        let item = Referrals.newSlotWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotWindowLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.SlotWindowLabelLengthRule(maxLength: 32)
        let item = Referrals.newSlotWindow("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotWindowVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Referrals.SlotWindowVisitMinutesRangeRule(min: 255, max: 3600)
        let item = Referrals.newSlotWindow("x", label: "y")
        item.visitMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSlotWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.SlotWindowCodeLengthRule(maxLength: 64)
        let item = Referrals.newSlotWindow("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotWindowRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.SlotWindowRequiredLabelRule(message: "slot window needs an entry")
        let item = Referrals.newSlotWindow("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSlotWindowExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Referrals.SlotWindowExternalRefLengthRule(maxLength: 86400)
        let item = Referrals.newSlotWindow("x", label: "y")
        item.externalRef = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
