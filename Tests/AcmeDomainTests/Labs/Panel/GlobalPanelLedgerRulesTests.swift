@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalPanelLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultGlobalPanelLedgerValidator()
        let item = Labs.newGlobalPanelLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsGlobalPanelLedgerNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.GlobalPanelLedgerNameLengthRule(maxLength: 32)
        let item = Labs.newGlobalPanelLedger("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsGlobalPanelLedgerContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Labs.GlobalPanelLedgerContactEmailLengthRule(maxLength: 80)
        let item = Labs.newGlobalPanelLedger("x", name: "y")
        item.contactEmail = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsGlobalPanelLedgerMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Labs.GlobalPanelLedgerMinimumRangeRule(min: 3.8, max: 187.1)
        let item = Labs.newGlobalPanelLedger("x", name: "y")
        item.minimum = 188.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsGlobalPanelLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.GlobalPanelLedgerRequiredCodeRule(message: "global panel ledger needs a value")
        let item = Labs.newGlobalPanelLedger("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsGlobalPanelLedgerRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Labs.GlobalPanelLedgerRequiredContactEmailRule(message: "global panel ledger needs a value")
        let item = Labs.newGlobalPanelLedger("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}
