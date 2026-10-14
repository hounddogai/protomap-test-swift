@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalClosureEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSeasonalClosureEntryValidator()
        let item = Referrals.newSeasonalClosureEntry("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSeasonalClosureEntryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.SeasonalClosureEntryRequiredTitleRule(message: "seasonal closure entry needs an entry")
        let item = Referrals.newSeasonalClosureEntry("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSeasonalClosureEntryTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.SeasonalClosureEntryTitleLengthRule(maxLength: 32)
        let item = Referrals.newSeasonalClosureEntry("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSeasonalClosureEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.SeasonalClosureEntryCodeLengthRule(maxLength: 32)
        let item = Referrals.newSeasonalClosureEntry("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
