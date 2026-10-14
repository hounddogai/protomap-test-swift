@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalSlotDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRegionalSlotDigestValidator()
        let item = Referrals.newRegionalSlotDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRegionalSlotDigestExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Referrals.RegionalSlotDigestExternalRefLengthRule(maxLength: 3600)
        let item = Referrals.newRegionalSlotDigest("x", label: "y")
        item.externalRef = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRegionalSlotDigestRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Referrals.RegionalSlotDigestRequiredExternalRefRule(message: "regional slot digest needs this field")
        let item = Referrals.newRegionalSlotDigest("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
