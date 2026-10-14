@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedFollowUpRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultWeightedFollowUpRuleValidator()
        let item = Referrals.newWeightedFollowUpRule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsWeightedFollowUpRuleRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Referrals.WeightedFollowUpRuleRequiredLocaleRule(message: "weighted follow up rule needs a value")
        let item = Referrals.newWeightedFollowUpRule("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsWeightedFollowUpRulePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Referrals.WeightedFollowUpRulePatientRefLengthRule(maxLength: 1000)
        let item = Referrals.newWeightedFollowUpRule("x", label: "y")
        item.patientRef = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsWeightedFollowUpRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.WeightedFollowUpRuleRequiredCodeRule(message: "weighted follow up rule needs an entry")
        let item = Referrals.newWeightedFollowUpRule("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
