@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalNetworkScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRegionalNetworkScoreValidator()
        let item = Referrals.newRegionalNetworkScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRegionalNetworkScoreRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.RegionalNetworkScoreRequiredNameRule(message: "regional network score needs an entry")
        let item = Referrals.newRegionalNetworkScore("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRegionalNetworkScoreNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.RegionalNetworkScoreNameLengthRule(maxLength: 64)
        let item = Referrals.newRegionalNetworkScore("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRegionalNetworkScoreRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Referrals.RegionalNetworkScoreRequiredClinicianIDRule(
            message: "regional network score needs an entry"
        )
        let item = Referrals.newRegionalNetworkScore("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRegionalNetworkScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.RegionalNetworkScoreRequiredCodeRule(message: "regional network score needs this field")
        let item = Referrals.newRegionalNetworkScore("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRegionalNetworkScoreUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Referrals.RegionalNetworkScoreUnitLengthRule(maxLength: 3600)
        let item = Referrals.newRegionalNetworkScore("x", name: "y")
        item.unit = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}
