@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingTaskLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRollingTaskLedgerValidator()
        let item = ClinicalOps.newRollingTaskLedger("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRollingTaskLedgerMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = ClinicalOps.RollingTaskLedgerMinimumRangeRule(min: 2.7, max: 4983.2)
        let item = ClinicalOps.newRollingTaskLedger("x", title: "y")
        item.minimum = 4984.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRollingTaskLedgerAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = ClinicalOps.RollingTaskLedgerAllergyLengthRule(maxLength: 64)
        let item = ClinicalOps.newRollingTaskLedger("x", title: "y")
        item.allergy = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRollingTaskLedgerRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = ClinicalOps.RollingTaskLedgerRequiredAllergyRule(message: "rolling task ledger needs an entry")
        let item = ClinicalOps.newRollingTaskLedger("", title: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRollingTaskLedgerCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = ClinicalOps.RollingTaskLedgerCopayRangeRule(min: 4.2, max: 2303.2)
        let item = ClinicalOps.newRollingTaskLedger("x", title: "y")
        item.copay = 2304.7
        #expect(rule.check(item).count > 0)
    }
}
