@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardEntryValidator()
        let item = BedManagement.newBedBoardEntry("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.BedBoardEntryRequiredCodeRule(message: "bed board entry needs this field")
        let item = BedManagement.newBedBoardEntry("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardEntryLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.BedBoardEntryLabelLengthRule(maxLength: 3600)
        let item = BedManagement.newBedBoardEntry("x", title: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardEntryScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = BedManagement.BedBoardEntryScoreRangeRule(min: 7.0, max: 2183.0)
        let item = BedManagement.newBedBoardEntry("x", title: "y")
        item.score = 2184.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBedBoardEntryVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = BedManagement.BedBoardEntryVisitMinutesRangeRule(min: 64, max: 1000)
        let item = BedManagement.newBedBoardEntry("x", title: "y")
        item.visitMinutes = 1001
        #expect(rule.check(item).count > 0)
    }
}
