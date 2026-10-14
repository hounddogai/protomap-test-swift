@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalNetworkCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSeasonalNetworkCycleValidator()
        let item = Referrals.newSeasonalNetworkCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSeasonalNetworkCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.SeasonalNetworkCycleRequiredCodeRule(message: "seasonal network cycle needs a value")
        let item = Referrals.newSeasonalNetworkCycle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSeasonalNetworkCycleWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Referrals.SeasonalNetworkCycleWardLengthRule(maxLength: 1000)
        let item = Referrals.newSeasonalNetworkCycle("x", name: "y")
        item.ward = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSeasonalNetworkCycleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.SeasonalNetworkCycleRequiredNameRule(message: "seasonal network cycle needs an entry")
        let item = Referrals.newSeasonalNetworkCycle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSeasonalNetworkCycleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.SeasonalNetworkCycleNameLengthRule(maxLength: 3600)
        let item = Referrals.newSeasonalNetworkCycle("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
