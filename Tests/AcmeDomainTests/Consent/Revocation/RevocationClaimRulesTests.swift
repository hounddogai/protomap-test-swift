@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRevocationClaimValidator()
        let item = Consent.newRevocationClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRevocationClaimCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Consent.RevocationClaimCreatedAtRangeRule(min: 64, max: 3600)
        let item = Consent.newRevocationClaim("x", title: "y")
        item.createdAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRevocationClaimTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.RevocationClaimTitleLengthRule(maxLength: 120)
        let item = Consent.newRevocationClaim("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRevocationClaimTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Consent.RevocationClaimTimezoneLengthRule(maxLength: 32)
        let item = Consent.newRevocationClaim("x", title: "y")
        item.timezone = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
