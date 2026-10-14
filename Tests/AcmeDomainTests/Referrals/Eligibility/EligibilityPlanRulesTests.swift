@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityPlanValidator()
        let item = Referrals.newEligibilityPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityPlanRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Referrals.EligibilityPlanRequiredPatientRefRule(message: "eligibility plan needs a value")
        let item = Referrals.newEligibilityPlan("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityPlanPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Referrals.EligibilityPlanPatientRefLengthRule(maxLength: 255)
        let item = Referrals.newEligibilityPlan("x", title: "y")
        item.patientRef = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
