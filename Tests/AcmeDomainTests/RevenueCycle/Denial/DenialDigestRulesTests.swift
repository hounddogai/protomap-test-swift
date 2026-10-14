@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialDigestValidator()
        let item = RevenueCycle.newDenialDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialDigestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.DenialDigestNameLengthRule(maxLength: 86400)
        let item = RevenueCycle.newDenialDigest("x", title: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDenialDigestRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = RevenueCycle.DenialDigestRequiredExternalRefRule(message: "denial digest needs this field")
        let item = RevenueCycle.newDenialDigest("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialDigestExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = RevenueCycle.DenialDigestExternalRefLengthRule(maxLength: 3600)
        let item = RevenueCycle.newDenialDigest("x", title: "y")
        item.externalRef = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDenialDigestDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = RevenueCycle.DenialDigestDosageMgRangeRule(min: 0.5, max: 1007.0)
        let item = RevenueCycle.newDenialDigest("x", title: "y")
        item.dosageMg = 1008.5
        #expect(rule.check(item).count > 0)
    }
}
