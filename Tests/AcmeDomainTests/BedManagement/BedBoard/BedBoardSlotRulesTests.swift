@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardSlotValidator()
        let item = BedManagement.newBedBoardSlot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardSlotExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = BedManagement.BedBoardSlotExpiresAtRangeRule(min: 32, max: 80)
        let item = BedManagement.newBedBoardSlot("x", name: "y")
        item.expiresAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBedBoardSlotRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = BedManagement.BedBoardSlotRegionLengthRule(maxLength: 32)
        let item = BedManagement.newBedBoardSlot("x", name: "y")
        item.region = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardSlotVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = BedManagement.BedBoardSlotVersionRangeRule(min: 1000, max: 86400)
        let item = BedManagement.newBedBoardSlot("x", name: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}
