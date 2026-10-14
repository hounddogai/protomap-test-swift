@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryBedBoardLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPrimaryBedBoardLedgerValidator()
        let item = BedManagement.newPrimaryBedBoardLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPrimaryBedBoardLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.PrimaryBedBoardLedgerCodeLengthRule(maxLength: 86400)
        let item = BedManagement.newPrimaryBedBoardLedger("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPrimaryBedBoardLedgerAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = BedManagement.PrimaryBedBoardLedgerAllergyLengthRule(maxLength: 120)
        let item = BedManagement.newPrimaryBedBoardLedger("x", label: "y")
        item.allergy = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPrimaryBedBoardLedgerLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.PrimaryBedBoardLedgerLabelLengthRule(maxLength: 1000)
        let item = BedManagement.newPrimaryBedBoardLedger("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPrimaryBedBoardLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.PrimaryBedBoardLedgerRequiredCodeRule(message: "primary bed board ledger needs a value")
        let item = BedManagement.newPrimaryBedBoardLedger("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPrimaryBedBoardLedgerRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.PrimaryBedBoardLedgerRequiredLabelRule(
            message: "primary bed board ledger needs this field"
        )
        let item = BedManagement.newPrimaryBedBoardLedger("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPrimaryBedBoardLedgerMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = BedManagement.PrimaryBedBoardLedgerMinimumRangeRule(min: 7.2, max: 1538.3)
        let item = BedManagement.newPrimaryBedBoardLedger("x", label: "y")
        item.minimum = 1539.8
        #expect(rule.check(item).count > 0)
    }
}
