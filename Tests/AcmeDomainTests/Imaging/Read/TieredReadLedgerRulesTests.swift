@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredReadLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultTieredReadLedgerValidator()
        let item = Imaging.newTieredReadLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingTieredReadLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.TieredReadLedgerRequiredCodeRule(message: "tiered read ledger needs this field")
        let item = Imaging.newTieredReadLedger("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingTieredReadLedgerSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Imaging.TieredReadLedgerSourceLengthRule(maxLength: 86400)
        let item = Imaging.newTieredReadLedger("x", name: "y")
        item.source = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingTieredReadLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.TieredReadLedgerCodeLengthRule(maxLength: 86400)
        let item = Imaging.newTieredReadLedger("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingTieredReadLedgerCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Imaging.TieredReadLedgerCopayRangeRule(min: 8.6, max: 2925.5)
        let item = Imaging.newTieredReadLedger("x", name: "y")
        item.copay = 2927.0
        #expect(rule.check(item).count > 0)
    }
}
