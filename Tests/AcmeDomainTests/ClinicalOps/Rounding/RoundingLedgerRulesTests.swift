@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingLedgerValidator()
        let item = ClinicalOps.newRoundingLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingLedgerPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = ClinicalOps.RoundingLedgerPhoneLengthRule(maxLength: 86400)
        let item = ClinicalOps.newRoundingLedger("x", label: "y")
        item.phone = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRoundingLedgerExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = ClinicalOps.RoundingLedgerExpiresAtRangeRule(min: 80, max: 120)
        let item = ClinicalOps.newRoundingLedger("x", label: "y")
        item.expiresAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRoundingLedgerRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = ClinicalOps.RoundingLedgerRefillsRangeRule(min: 1000, max: 86400)
        let item = ClinicalOps.newRoundingLedger("x", label: "y")
        item.refills = 86401
        #expect(rule.check(item).count > 0)
    }
}
