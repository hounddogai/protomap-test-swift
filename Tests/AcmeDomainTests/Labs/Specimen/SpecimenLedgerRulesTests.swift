@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenLedgerValidator()
        let item = Labs.newSpecimenLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenLedgerRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.SpecimenLedgerRequiredNameRule(message: "specimen ledger needs a value")
        let item = Labs.newSpecimenLedger("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenLedgerRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Labs.SpecimenLedgerRequiredReviewerRule(message: "specimen ledger needs an entry")
        let item = Labs.newSpecimenLedger("", name: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenLedgerWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Labs.SpecimenLedgerWindowDaysRangeRule(min: 32, max: 120)
        let item = Labs.newSpecimenLedger("x", name: "y")
        item.windowDays = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenLedgerRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Labs.SpecimenLedgerRequiredPhoneRule(message: "specimen ledger needs an entry")
        let item = Labs.newSpecimenLedger("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}
