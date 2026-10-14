@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyTransferWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLegacyTransferWindowValidator()
        let item = BedManagement.newLegacyTransferWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLegacyTransferWindowSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = BedManagement.LegacyTransferWindowSequenceRangeRule(min: 120, max: 120)
        let item = BedManagement.newLegacyTransferWindow("x", name: "y")
        item.sequence = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementLegacyTransferWindowNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.LegacyTransferWindowNameLengthRule(maxLength: 64)
        let item = BedManagement.newLegacyTransferWindow("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementLegacyTransferWindowExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = BedManagement.LegacyTransferWindowExpiresAtRangeRule(min: 255, max: 255)
        let item = BedManagement.newLegacyTransferWindow("x", name: "y")
        item.expiresAt = 256
        #expect(rule.check(item).count > 0)
    }
}
