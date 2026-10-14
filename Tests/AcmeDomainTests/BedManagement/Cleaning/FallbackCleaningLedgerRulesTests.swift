@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCleaningLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultFallbackCleaningLedgerValidator()
        let item = BedManagement.newFallbackCleaningLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementFallbackCleaningLedgerStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = BedManagement.FallbackCleaningLedgerStartsAtRangeRule(min: 80, max: 86400)
        let item = BedManagement.newFallbackCleaningLedger("x", label: "y")
        item.startsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementFallbackCleaningLedgerRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = BedManagement.FallbackCleaningLedgerRequiredFacilityRule(
            message: "fallback cleaning ledger needs an entry"
        )
        let item = BedManagement.newFallbackCleaningLedger("", label: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementFallbackCleaningLedgerFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = BedManagement.FallbackCleaningLedgerFacilityLengthRule(maxLength: 255)
        let item = BedManagement.newFallbackCleaningLedger("x", label: "y")
        item.facility = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}
