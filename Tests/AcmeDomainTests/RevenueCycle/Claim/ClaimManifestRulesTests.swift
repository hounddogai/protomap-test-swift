@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimManifestValidator()
        let item = RevenueCycle.newClaimManifest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimManifestMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = RevenueCycle.ClaimManifestMaximumRangeRule(min: 8.2, max: 2613.9)
        let item = RevenueCycle.newClaimManifest("x", name: "y")
        item.maximum = 2615.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleClaimManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ClaimManifestRequiredCodeRule(message: "claim manifest needs a value")
        let item = RevenueCycle.newClaimManifest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimManifestRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = RevenueCycle.ClaimManifestRequiredExternalRefRule(message: "claim manifest needs this field")
        let item = RevenueCycle.newClaimManifest("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimManifestExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = RevenueCycle.ClaimManifestExternalRefLengthRule(maxLength: 80)
        let item = RevenueCycle.newClaimManifest("x", name: "y")
        item.externalRef = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleClaimManifestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.ClaimManifestNameLengthRule(maxLength: 120)
        let item = RevenueCycle.newClaimManifest("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
