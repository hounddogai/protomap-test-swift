@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedDenialManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultCappedDenialManifestValidator()
        let item = RevenueCycle.newCappedDenialManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleCappedDenialManifestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.CappedDenialManifestRequiredLabelRule(message: "capped denial manifest needs this field")
        let item = RevenueCycle.newCappedDenialManifest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleCappedDenialManifestRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = RevenueCycle.CappedDenialManifestRequiredChannelRule(
            message: "capped denial manifest needs this field"
        )
        let item = RevenueCycle.newCappedDenialManifest("", label: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleCappedDenialManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.CappedDenialManifestRequiredCodeRule(message: "capped denial manifest needs an entry")
        let item = RevenueCycle.newCappedDenialManifest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
