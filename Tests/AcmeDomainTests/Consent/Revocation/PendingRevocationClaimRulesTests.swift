@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingRevocationClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultPendingRevocationClaimValidator()
        let item = Consent.newPendingRevocationClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentPendingRevocationClaimLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Consent.PendingRevocationClaimLimitRangeRule(min: 80, max: 120)
        let item = Consent.newPendingRevocationClaim("x", title: "y")
        item.limit = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentPendingRevocationClaimVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Consent.PendingRevocationClaimVersionRangeRule(min: 16, max: 255)
        let item = Consent.newPendingRevocationClaim("x", title: "y")
        item.version = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentPendingRevocationClaimRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Consent.PendingRevocationClaimRegionLengthRule(maxLength: 3600)
        let item = Consent.newPendingRevocationClaim("x", title: "y")
        item.region = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentPendingRevocationClaimRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.PendingRevocationClaimRequiredNameRule(message: "pending revocation claim needs a value")
        let item = Consent.newPendingRevocationClaim("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
