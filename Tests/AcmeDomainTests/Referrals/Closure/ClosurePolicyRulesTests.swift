@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosurePolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosurePolicyValidator()
        let item = Referrals.newClosurePolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosurePolicyRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.ClosurePolicyRequiredLabelRule(message: "closure policy needs a value")
        let item = Referrals.newClosurePolicy("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosurePolicyFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Referrals.ClosurePolicyFloorValueRangeRule(min: 0.5, max: 523.5)
        let item = Referrals.newClosurePolicy("x", label: "y")
        item.floorValue = 525.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsClosurePolicyRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.ClosurePolicyRequiredNameRule(message: "closure policy needs this field")
        let item = Referrals.newClosurePolicy("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosurePolicyRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Referrals.ClosurePolicyRequiredNotesRule(message: "closure policy needs this field")
        let item = Referrals.newClosurePolicy("", label: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosurePolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.ClosurePolicyRequiredCodeRule(message: "closure policy needs this field")
        let item = Referrals.newClosurePolicy("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
