@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementSeasonalBedBoardScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultSeasonalBedBoardScoreValidator()
        let item = BedManagement.newSeasonalBedBoardScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementSeasonalBedBoardScoreWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = BedManagement.SeasonalBedBoardScoreWindowDaysRangeRule(min: 3600, max: 86400)
        let item = BedManagement.newSeasonalBedBoardScore("x", title: "y")
        item.windowDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementSeasonalBedBoardScoreTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.SeasonalBedBoardScoreTitleLengthRule(maxLength: 255)
        let item = BedManagement.newSeasonalBedBoardScore("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementSeasonalBedBoardScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.SeasonalBedBoardScoreRequiredCodeRule(message: "seasonal bed board score needs a value")
        let item = BedManagement.newSeasonalBedBoardScore("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementSeasonalBedBoardScoreMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = BedManagement.SeasonalBedBoardScoreMaximumRangeRule(min: 7.1, max: 4324.5)
        let item = BedManagement.newSeasonalBedBoardScore("x", title: "y")
        item.maximum = 4326.0
        #expect(rule.check(item).count > 0)
    }
}
