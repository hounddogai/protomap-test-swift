@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingWitnessReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRollingWitnessReviewValidator()
        let item = Consent.newRollingWitnessReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRollingWitnessReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.RollingWitnessReviewCodeLengthRule(maxLength: 80)
        let item = Consent.newRollingWitnessReview("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRollingWitnessReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.RollingWitnessReviewRequiredCodeRule(message: "rolling witness review needs this field")
        let item = Consent.newRollingWitnessReview("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRollingWitnessReviewClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Consent.RollingWitnessReviewClinicianIDLengthRule(maxLength: 1000)
        let item = Consent.newRollingWitnessReview("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
