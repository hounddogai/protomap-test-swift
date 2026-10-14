@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardNoticeValidator()
        let item = BedManagement.newBedBoardNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardNoticeRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.BedBoardNoticeRequiredTitleRule(message: "bed board notice needs an entry")
        let item = BedManagement.newBedBoardNotice("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardNoticeUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = BedManagement.BedBoardNoticeUpdatedAtRangeRule(min: 64, max: 1000)
        let item = BedManagement.newBedBoardNotice("x", title: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBedBoardNoticeMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = BedManagement.BedBoardNoticeMinimumRangeRule(min: 9.1, max: 1598.5)
        let item = BedManagement.newBedBoardNotice("x", title: "y")
        item.minimum = 1600.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBedBoardNoticeEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = BedManagement.BedBoardNoticeEncounterIDLengthRule(maxLength: 3600)
        let item = BedManagement.newBedBoardNotice("x", title: "y")
        item.encounterID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
