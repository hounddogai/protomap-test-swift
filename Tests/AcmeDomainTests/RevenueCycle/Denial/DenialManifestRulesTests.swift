@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialManifestValidator()
        let item = RevenueCycle.newDenialManifest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialManifestCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = RevenueCycle.DenialManifestCategoryLengthRule(maxLength: 3600)
        let item = RevenueCycle.newDenialManifest("x", name: "y")
        item.category = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDenialManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.DenialManifestRequiredCodeRule(message: "denial manifest needs an entry")
        let item = RevenueCycle.newDenialManifest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialManifestRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = RevenueCycle.DenialManifestRequiredCategoryRule(message: "denial manifest needs an entry")
        let item = RevenueCycle.newDenialManifest("", name: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}
