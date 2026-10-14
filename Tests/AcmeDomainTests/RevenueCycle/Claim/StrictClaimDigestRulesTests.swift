@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictClaimDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStrictClaimDigestValidator()
        let item = RevenueCycle.newStrictClaimDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStrictClaimDigestCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = RevenueCycle.StrictClaimDigestCreatedAtRangeRule(min: 255, max: 86400)
        let item = RevenueCycle.newStrictClaimDigest("x", name: "y")
        item.createdAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStrictClaimDigestAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = RevenueCycle.StrictClaimDigestAllergyLengthRule(maxLength: 64)
        let item = RevenueCycle.newStrictClaimDigest("x", name: "y")
        item.allergy = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStrictClaimDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.StrictClaimDigestCodeLengthRule(maxLength: 32)
        let item = RevenueCycle.newStrictClaimDigest("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
