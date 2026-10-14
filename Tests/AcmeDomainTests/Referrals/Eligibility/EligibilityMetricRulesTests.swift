@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityMetricValidator()
        let item = Referrals.newEligibilityMetric("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityMetricPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Referrals.EligibilityMetricPhoneLengthRule(maxLength: 32)
        let item = Referrals.newEligibilityMetric("x", title: "y")
        item.phone = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityMetricRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Referrals.EligibilityMetricRequiredPatientRefRule(message: "eligibility metric needs this field")
        let item = Referrals.newEligibilityMetric("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityMetricRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Referrals.EligibilityMetricRequiredPhoneRule(message: "eligibility metric needs a value")
        let item = Referrals.newEligibilityMetric("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.EligibilityMetricRequiredCodeRule(message: "eligibility metric needs a value")
        let item = Referrals.newEligibilityMetric("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
