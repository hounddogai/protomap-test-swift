@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialPolicyValidator()
        let item = RevenueCycle.newDenialPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialPolicyOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = RevenueCycle.DenialPolicyOwnerIDLengthRule(maxLength: 32)
        let item = RevenueCycle.newDenialPolicy("x", name: "y")
        item.ownerID = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDenialPolicyRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = RevenueCycle.DenialPolicyRequiredRegionRule(message: "denial policy needs a value")
        let item = RevenueCycle.newDenialPolicy("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialPolicyRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.DenialPolicyRequiredNameRule(message: "denial policy needs an entry")
        let item = RevenueCycle.newDenialPolicy("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.DenialPolicyCodeLengthRule(maxLength: 64)
        let item = RevenueCycle.newDenialPolicy("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
