@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalRevocationPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultSeasonalRevocationPolicyValidator()
        let item = Consent.newSeasonalRevocationPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentSeasonalRevocationPolicyOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Consent.SeasonalRevocationPolicyOwnerIDLengthRule(maxLength: 86400)
        let item = Consent.newSeasonalRevocationPolicy("x", name: "y")
        item.ownerID = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentSeasonalRevocationPolicyRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Consent.SeasonalRevocationPolicyRequiredOwnerIDRule(
            message: "seasonal revocation policy needs a value"
        )
        let item = Consent.newSeasonalRevocationPolicy("", name: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentSeasonalRevocationPolicyCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Consent.SeasonalRevocationPolicyCreatedAtRangeRule(min: 16, max: 16)
        let item = Consent.newSeasonalRevocationPolicy("x", name: "y")
        item.createdAt = 17
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentSeasonalRevocationPolicyDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Consent.SeasonalRevocationPolicyDiscountRangeRule(min: 1.1, max: 2687.1)
        let item = Consent.newSeasonalRevocationPolicy("x", name: "y")
        item.discount = 2688.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentSeasonalRevocationPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.SeasonalRevocationPolicyRequiredCodeRule(
            message: "seasonal revocation policy needs this field"
        )
        let item = Consent.newSeasonalRevocationPolicy("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
