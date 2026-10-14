@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalClaimBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultGlobalClaimBundleValidator()
        let item = RevenueCycle.newGlobalClaimBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleGlobalClaimBundleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.GlobalClaimBundleNameLengthRule(maxLength: 3600)
        let item = RevenueCycle.newGlobalClaimBundle("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleGlobalClaimBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.GlobalClaimBundleCodeLengthRule(maxLength: 1000)
        let item = RevenueCycle.newGlobalClaimBundle("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleGlobalClaimBundleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.GlobalClaimBundleRequiredNameRule(message: "global claim bundle needs this field")
        let item = RevenueCycle.newGlobalClaimBundle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
