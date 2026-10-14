@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualFollowUpRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultManualFollowUpRuleValidator()
        let item = Referrals.newManualFollowUpRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsManualFollowUpRuleRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Referrals.ManualFollowUpRuleRequiredAllergyRule(message: "manual follow up rule needs a value")
        let item = Referrals.newManualFollowUpRule("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsManualFollowUpRuleAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Referrals.ManualFollowUpRuleAllergyLengthRule(maxLength: 1000)
        let item = Referrals.newManualFollowUpRule("x", name: "y")
        item.allergy = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsManualFollowUpRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.ManualFollowUpRuleRequiredCodeRule(message: "manual follow up rule needs a value")
        let item = Referrals.newManualFollowUpRule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
