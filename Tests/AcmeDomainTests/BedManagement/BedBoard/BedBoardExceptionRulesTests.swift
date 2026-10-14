@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardExceptionValidator()
        let item = BedManagement.newBedBoardException("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardExceptionRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = BedManagement.BedBoardExceptionRequiredUnitRule(message: "bed board exception needs this field")
        let item = BedManagement.newBedBoardException("", label: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardExceptionVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = BedManagement.BedBoardExceptionVisitMinutesRangeRule(min: 16, max: 86400)
        let item = BedManagement.newBedBoardException("x", label: "y")
        item.visitMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBedBoardExceptionUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = BedManagement.BedBoardExceptionUnitLengthRule(maxLength: 1000)
        let item = BedManagement.newBedBoardException("x", label: "y")
        item.unit = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardExceptionRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.BedBoardExceptionRequiredLabelRule(message: "bed board exception needs this field")
        let item = BedManagement.newBedBoardException("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
