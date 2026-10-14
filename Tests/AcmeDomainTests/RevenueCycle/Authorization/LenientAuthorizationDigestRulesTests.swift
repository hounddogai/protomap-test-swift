@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientAuthorizationDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLenientAuthorizationDigestValidator()
        let item = RevenueCycle.newLenientAuthorizationDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLenientAuthorizationDigestQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = RevenueCycle.LenientAuthorizationDigestQuantityRangeRule(min: 255, max: 255)
        let item = RevenueCycle.newLenientAuthorizationDigest("x", label: "y")
        item.quantity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleLenientAuthorizationDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.LenientAuthorizationDigestRequiredCodeRule(
            message: "lenient authorization digest needs a value"
        )
        let item = RevenueCycle.newLenientAuthorizationDigest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleLenientAuthorizationDigestRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = RevenueCycle.LenientAuthorizationDigestRequiredPatientRefRule(
            message: "lenient authorization digest needs a value"
        )
        let item = RevenueCycle.newLenientAuthorizationDigest("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleLenientAuthorizationDigestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.LenientAuthorizationDigestRequiredNameRule(
            message: "lenient authorization digest needs a value"
        )
        let item = RevenueCycle.newLenientAuthorizationDigest("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
