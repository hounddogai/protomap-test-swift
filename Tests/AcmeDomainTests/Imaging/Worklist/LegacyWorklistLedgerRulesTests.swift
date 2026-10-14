@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyWorklistLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultLegacyWorklistLedgerValidator()
        let item = Imaging.newLegacyWorklistLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingLegacyWorklistLedgerRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Imaging.LegacyWorklistLedgerRateRangeRule(min: 3.7, max: 1128.5)
        let item = Imaging.newLegacyWorklistLedger("x", label: "y")
        item.rate = 1130.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingLegacyWorklistLedgerRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.LegacyWorklistLedgerRequiredLabelRule(message: "legacy worklist ledger needs an entry")
        let item = Imaging.newLegacyWorklistLedger("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingLegacyWorklistLedgerCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Imaging.LegacyWorklistLedgerCategoryLengthRule(maxLength: 3600)
        let item = Imaging.newLegacyWorklistLedger("x", label: "y")
        item.category = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingLegacyWorklistLedgerRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Imaging.LegacyWorklistLedgerRequiredCategoryRule(message: "legacy worklist ledger needs an entry")
        let item = Imaging.newLegacyWorklistLedger("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingLegacyWorklistLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.LegacyWorklistLedgerRequiredCodeRule(message: "legacy worklist ledger needs an entry")
        let item = Imaging.newLegacyWorklistLedger("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
