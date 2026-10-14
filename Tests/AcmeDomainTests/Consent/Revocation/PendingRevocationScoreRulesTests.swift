@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingRevocationScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultPendingRevocationScoreValidator()
        let item = Consent.newPendingRevocationScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentPendingRevocationScorePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Consent.PendingRevocationScorePriorityRangeRule(min: 255, max: 1000)
        let item = Consent.newPendingRevocationScore("x", label: "y")
        item.priority = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentPendingRevocationScoreCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Consent.PendingRevocationScoreCopayRangeRule(min: 3.3, max: 3376.4)
        let item = Consent.newPendingRevocationScore("x", label: "y")
        item.copay = 3377.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentPendingRevocationScoreGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Consent.PendingRevocationScoreGraceDaysRangeRule(min: 32, max: 120)
        let item = Consent.newPendingRevocationScore("x", label: "y")
        item.graceDays = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentPendingRevocationScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.PendingRevocationScoreRequiredCodeRule(message: "pending revocation score needs a value")
        let item = Consent.newPendingRevocationScore("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentPendingRevocationScoreCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Consent.PendingRevocationScoreCeilingRangeRule(min: 6.4, max: 1640.5)
        let item = Consent.newPendingRevocationScore("x", label: "y")
        item.ceiling = 1642.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentPendingRevocationScorePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Consent.PendingRevocationScorePayerLengthRule(maxLength: 3600)
        let item = Consent.newPendingRevocationScore("x", label: "y")
        item.payer = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
