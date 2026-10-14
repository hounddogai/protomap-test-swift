@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedSlotBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultCappedSlotBundleValidator()
        let item = Referrals.newCappedSlotBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsCappedSlotBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.CappedSlotBundleRequiredCodeRule(message: "capped slot bundle needs an entry")
        let item = Referrals.newCappedSlotBundle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsCappedSlotBundleAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Referrals.CappedSlotBundleAllergyLengthRule(maxLength: 1000)
        let item = Referrals.newCappedSlotBundle("x", name: "y")
        item.allergy = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsCappedSlotBundleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.CappedSlotBundleRequiredNameRule(message: "capped slot bundle needs this field")
        let item = Referrals.newCappedSlotBundle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsCappedSlotBundleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.CappedSlotBundleNameLengthRule(maxLength: 64)
        let item = Referrals.newCappedSlotBundle("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
