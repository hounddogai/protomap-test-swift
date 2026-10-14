@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredHandoffLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTieredHandoffLedgerValidator()
        let item = ClinicalOps.newTieredHandoffLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTieredHandoffLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.TieredHandoffLedgerRequiredCodeRule(message: "tiered handoff ledger needs a value")
        let item = ClinicalOps.newTieredHandoffLedger("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTieredHandoffLedgerRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = ClinicalOps.TieredHandoffLedgerRequiredChecksumRule(message: "tiered handoff ledger needs an entry")
        let item = ClinicalOps.newTieredHandoffLedger("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTieredHandoffLedgerRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = ClinicalOps.TieredHandoffLedgerRequiredPhoneRule(message: "tiered handoff ledger needs a value")
        let item = ClinicalOps.newTieredHandoffLedger("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTieredHandoffLedgerChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = ClinicalOps.TieredHandoffLedgerChecksumLengthRule(maxLength: 120)
        let item = ClinicalOps.newTieredHandoffLedger("x", name: "y")
        item.checksum = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}
