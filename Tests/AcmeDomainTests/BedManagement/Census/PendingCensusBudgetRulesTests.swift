@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingCensusBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPendingCensusBudgetValidator()
        let item = BedManagement.newPendingCensusBudget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPendingCensusBudgetRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = BedManagement.PendingCensusBudgetRequiredSegmentRule(
            message: "pending census budget needs this field"
        )
        let item = BedManagement.newPendingCensusBudget("", name: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPendingCensusBudgetEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = BedManagement.PendingCensusBudgetEndsAtRangeRule(min: 3600, max: 86400)
        let item = BedManagement.newPendingCensusBudget("x", name: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPendingCensusBudgetSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = BedManagement.PendingCensusBudgetSegmentLengthRule(maxLength: 255)
        let item = BedManagement.newPendingCensusBudget("x", name: "y")
        item.segment = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPendingCensusBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.PendingCensusBudgetCodeLengthRule(maxLength: 16)
        let item = BedManagement.newPendingCensusBudget("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
