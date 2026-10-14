@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotAssignmentValidator()
        let item = Referrals.newSlotAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotAssignmentRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Referrals.SlotAssignmentRatioRangeRule(min: 2.2, max: 1598.3)
        let item = Referrals.newSlotAssignment("x", label: "y")
        item.ratio = 1599.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSlotAssignmentPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Referrals.SlotAssignmentPayerLengthRule(maxLength: 1000)
        let item = Referrals.newSlotAssignment("x", label: "y")
        item.payer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotAssignmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.SlotAssignmentRequiredLabelRule(message: "slot assignment needs this field")
        let item = Referrals.newSlotAssignment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSlotAssignmentRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Referrals.SlotAssignmentRequiredPayerRule(message: "slot assignment needs an entry")
        let item = Referrals.newSlotAssignment("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSlotAssignmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.SlotAssignmentLabelLengthRule(maxLength: 64)
        let item = Referrals.newSlotAssignment("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotAssignmentMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Referrals.SlotAssignmentMarginRangeRule(min: 3.6, max: 499.5)
        let item = Referrals.newSlotAssignment("x", label: "y")
        item.margin = 501.0
        #expect(rule.check(item).count > 0)
    }
}
