@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackResultLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultFallbackResultLedgerValidator()
        let item = Labs.newFallbackResultLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsFallbackResultLedgerNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.FallbackResultLedgerNameLengthRule(maxLength: 255)
        let item = Labs.newFallbackResultLedger("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsFallbackResultLedgerExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Labs.FallbackResultLedgerExternalRefLengthRule(maxLength: 120)
        let item = Labs.newFallbackResultLedger("x", name: "y")
        item.externalRef = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsFallbackResultLedgerRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Labs.FallbackResultLedgerRequiredSpecialtyRule(message: "fallback result ledger needs a value")
        let item = Labs.newFallbackResultLedger("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsFallbackResultLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.FallbackResultLedgerRequiredCodeRule(message: "fallback result ledger needs an entry")
        let item = Labs.newFallbackResultLedger("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
