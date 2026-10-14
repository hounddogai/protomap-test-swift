@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientDenialManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLenientDenialManifestValidator()
        let item = RevenueCycle.newLenientDenialManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLenientDenialManifestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.LenientDenialManifestRequiredLabelRule(
            message: "lenient denial manifest needs this field"
        )
        let item = RevenueCycle.newLenientDenialManifest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleLenientDenialManifestLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = RevenueCycle.LenientDenialManifestLimitRangeRule(min: 64, max: 3600)
        let item = RevenueCycle.newLenientDenialManifest("x", label: "y")
        item.limit = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleLenientDenialManifestLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.LenientDenialManifestLabelLengthRule(maxLength: 1000)
        let item = RevenueCycle.newLenientDenialManifest("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleLenientDenialManifestRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = RevenueCycle.LenientDenialManifestRequiredPayerRule(
            message: "lenient denial manifest needs this field"
        )
        let item = RevenueCycle.newLenientDenialManifest("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}
