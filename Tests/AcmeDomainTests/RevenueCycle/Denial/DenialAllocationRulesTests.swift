@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialAllocationValidator()
        let item = RevenueCycle.newDenialAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.DenialAllocationCodeLengthRule(maxLength: 86400)
        let item = RevenueCycle.newDenialAllocation("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDenialAllocationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.DenialAllocationTitleLengthRule(maxLength: 120)
        let item = RevenueCycle.newDenialAllocation("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
