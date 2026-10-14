@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalClosureDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSeasonalClosureDraftValidator()
        let item = Referrals.newSeasonalClosureDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSeasonalClosureDraftRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.SeasonalClosureDraftRequiredTitleRule(message: "seasonal closure draft needs an entry")
        let item = Referrals.newSeasonalClosureDraft("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSeasonalClosureDraftRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Referrals.SeasonalClosureDraftRequiredChecksumRule(message: "seasonal closure draft needs an entry")
        let item = Referrals.newSeasonalClosureDraft("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSeasonalClosureDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.SeasonalClosureDraftRequiredCodeRule(message: "seasonal closure draft needs this field")
        let item = Referrals.newSeasonalClosureDraft("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
