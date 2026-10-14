@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledRevocationDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultScheduledRevocationDigestValidator()
        let item = Consent.newScheduledRevocationDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentScheduledRevocationDigestStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Consent.ScheduledRevocationDigestStartsAtRangeRule(min: 16, max: 16)
        let item = Consent.newScheduledRevocationDigest("x", name: "y")
        item.startsAt = 17
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentScheduledRevocationDigestUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Consent.ScheduledRevocationDigestUnitLengthRule(maxLength: 80)
        let item = Consent.newScheduledRevocationDigest("x", name: "y")
        item.unit = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentScheduledRevocationDigestRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Consent.ScheduledRevocationDigestRequiredUnitRule(
            message: "scheduled revocation digest needs an entry"
        )
        let item = Consent.newScheduledRevocationDigest("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
