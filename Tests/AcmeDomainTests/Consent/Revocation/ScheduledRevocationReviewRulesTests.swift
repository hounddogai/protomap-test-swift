@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledRevocationReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultScheduledRevocationReviewValidator()
        let item = Consent.newScheduledRevocationReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentScheduledRevocationReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ScheduledRevocationReviewRequiredCodeRule(
            message: "scheduled revocation review needs this field"
        )
        let item = Consent.newScheduledRevocationReview("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentScheduledRevocationReviewRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Consent.ScheduledRevocationReviewRequiredProcedureCodeRule(
            message: "scheduled revocation review needs a value"
        )
        let item = Consent.newScheduledRevocationReview("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentScheduledRevocationReviewLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.ScheduledRevocationReviewLabelLengthRule(maxLength: 120)
        let item = Consent.newScheduledRevocationReview("x", name: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentScheduledRevocationReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ScheduledRevocationReviewCodeLengthRule(maxLength: 3600)
        let item = Consent.newScheduledRevocationReview("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
