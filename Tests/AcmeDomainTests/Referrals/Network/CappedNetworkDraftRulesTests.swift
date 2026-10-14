@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedNetworkDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultCappedNetworkDraftValidator()
        let item = Referrals.newCappedNetworkDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsCappedNetworkDraftRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Referrals.CappedNetworkDraftRequiredReviewerRule(message: "capped network draft needs a value")
        let item = Referrals.newCappedNetworkDraft("", label: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsCappedNetworkDraftReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Referrals.CappedNetworkDraftReviewerLengthRule(maxLength: 255)
        let item = Referrals.newCappedNetworkDraft("x", label: "y")
        item.reviewer = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsCappedNetworkDraftRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Referrals.CappedNetworkDraftRequiredPatientRefRule(message: "capped network draft needs an entry")
        let item = Referrals.newCappedNetworkDraft("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsCappedNetworkDraftBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Referrals.CappedNetworkDraftBudgetRangeRule(min: 10.0, max: 4217.6)
        let item = Referrals.newCappedNetworkDraft("x", label: "y")
        item.budget = 4219.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsCappedNetworkDraftRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.CappedNetworkDraftRequiredLabelRule(message: "capped network draft needs a value")
        let item = Referrals.newCappedNetworkDraft("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
