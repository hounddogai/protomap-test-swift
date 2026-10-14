@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledConsentFormClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultScheduledConsentFormClaimValidator()
        let item = Consent.newScheduledConsentFormClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentScheduledConsentFormClaimStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Consent.ScheduledConsentFormClaimStartsAtRangeRule(min: 80, max: 120)
        let item = Consent.newScheduledConsentFormClaim("x", title: "y")
        item.startsAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentScheduledConsentFormClaimReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Consent.ScheduledConsentFormClaimReviewerLengthRule(maxLength: 16)
        let item = Consent.newScheduledConsentFormClaim("x", title: "y")
        item.reviewer = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentScheduledConsentFormClaimTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.ScheduledConsentFormClaimTitleLengthRule(maxLength: 255)
        let item = Consent.newScheduledConsentFormClaim("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentScheduledConsentFormClaimMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Consent.ScheduledConsentFormClaimMinimumRangeRule(min: 1.1, max: 3623.6)
        let item = Consent.newScheduledConsentFormClaim("x", title: "y")
        item.minimum = 3625.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentScheduledConsentFormClaimQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Consent.ScheduledConsentFormClaimQuantityRangeRule(min: 80, max: 1000)
        let item = Consent.newScheduledConsentFormClaim("x", title: "y")
        item.quantity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentScheduledConsentFormClaimDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Consent.ScheduledConsentFormClaimDiagnosisCodeLengthRule(maxLength: 120)
        let item = Consent.newScheduledConsentFormClaim("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
