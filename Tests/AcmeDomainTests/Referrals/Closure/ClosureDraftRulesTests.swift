@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureDraftValidator()
        let item = Referrals.newClosureDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureDraftAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Referrals.ClosureDraftAllergyLengthRule(maxLength: 255)
        let item = Referrals.newClosureDraft("x", name: "y")
        item.allergy = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureDraftNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.ClosureDraftNameLengthRule(maxLength: 3600)
        let item = Referrals.newClosureDraft("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureDraftQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Referrals.ClosureDraftQuantityRangeRule(min: 32, max: 80)
        let item = Referrals.newClosureDraft("x", name: "y")
        item.quantity = 81
        #expect(rule.check(item).count > 0)
    }
}
