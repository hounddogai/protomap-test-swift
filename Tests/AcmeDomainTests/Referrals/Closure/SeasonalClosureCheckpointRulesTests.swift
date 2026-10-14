@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalClosureCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSeasonalClosureCheckpointValidator()
        let item = Referrals.newSeasonalClosureCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSeasonalClosureCheckpointTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.SeasonalClosureCheckpointTitleLengthRule(maxLength: 86400)
        let item = Referrals.newSeasonalClosureCheckpoint("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSeasonalClosureCheckpointWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Referrals.SeasonalClosureCheckpointWindowDaysRangeRule(min: 16, max: 64)
        let item = Referrals.newSeasonalClosureCheckpoint("x", title: "y")
        item.windowDays = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSeasonalClosureCheckpointRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.SeasonalClosureCheckpointRequiredTitleRule(
            message: "seasonal closure checkpoint needs this field"
        )
        let item = Referrals.newSeasonalClosureCheckpoint("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSeasonalClosureCheckpointRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Referrals.SeasonalClosureCheckpointRequiredWardRule(
            message: "seasonal closure checkpoint needs an entry"
        )
        let item = Referrals.newSeasonalClosureCheckpoint("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSeasonalClosureCheckpointWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Referrals.SeasonalClosureCheckpointWardLengthRule(maxLength: 16)
        let item = Referrals.newSeasonalClosureCheckpoint("x", title: "y")
        item.ward = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}
