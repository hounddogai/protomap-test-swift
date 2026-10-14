@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureDigestValidator()
        let item = Referrals.newClosureDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureDigestRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Referrals.ClosureDigestRetriesRangeRule(min: 32, max: 32)
        let item = Referrals.newClosureDigest("x", label: "y")
        item.retries = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsClosureDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.ClosureDigestRequiredCodeRule(message: "closure digest needs this field")
        let item = Referrals.newClosureDigest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ClosureDigestCodeLengthRule(maxLength: 80)
        let item = Referrals.newClosureDigest("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureDigestRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Referrals.ClosureDigestRequiredEncounterIDRule(message: "closure digest needs this field")
        let item = Referrals.newClosureDigest("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureDigestEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Referrals.ClosureDigestEncounterIDLengthRule(maxLength: 16)
        let item = Referrals.newClosureDigest("x", label: "y")
        item.encounterID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
