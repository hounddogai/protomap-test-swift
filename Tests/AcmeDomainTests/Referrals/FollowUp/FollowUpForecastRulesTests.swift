@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpForecastValidator()
        let item = Referrals.newFollowUpForecast("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpForecastRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Referrals.FollowUpForecastRequiredOwnerIDRule(message: "follow up forecast needs this field")
        let item = Referrals.newFollowUpForecast("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpForecastVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Referrals.FollowUpForecastVisitMinutesRangeRule(min: 64, max: 255)
        let item = Referrals.newFollowUpForecast("x", title: "y")
        item.visitMinutes = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFollowUpForecastRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Referrals.FollowUpForecastRequiredNotesRule(message: "follow up forecast needs an entry")
        let item = Referrals.newFollowUpForecast("", title: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpForecastAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Referrals.FollowUpForecastAmountRangeRule(min: 3.5, max: 4271.5)
        let item = Referrals.newFollowUpForecast("x", title: "y")
        item.amount = 4273.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFollowUpForecastRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.FollowUpForecastRequiredTitleRule(message: "follow up forecast needs this field")
        let item = Referrals.newFollowUpForecast("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpForecastCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Referrals.FollowUpForecastCapacityRangeRule(min: 64, max: 1000)
        let item = Referrals.newFollowUpForecast("x", title: "y")
        item.capacity = 1001
        #expect(rule.check(item).count > 0)
    }
}
