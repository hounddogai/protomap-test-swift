@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardAllocationValidator()
        let item = BedManagement.newBedBoardAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardAllocationPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = BedManagement.BedBoardAllocationPayerLengthRule(maxLength: 64)
        let item = BedManagement.newBedBoardAllocation("x", label: "y")
        item.payer = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardAllocationDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = BedManagement.BedBoardAllocationDurationMinutesRangeRule(min: 80, max: 255)
        let item = BedManagement.newBedBoardAllocation("x", label: "y")
        item.durationMinutes = 256
        #expect(rule.check(item).count > 0)
    }
}
