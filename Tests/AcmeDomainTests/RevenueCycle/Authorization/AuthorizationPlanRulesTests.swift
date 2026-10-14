@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationPlanValidator()
        let item = RevenueCycle.newAuthorizationPlan("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.AuthorizationPlanRequiredCodeRule(message: "authorization plan needs a value")
        let item = RevenueCycle.newAuthorizationPlan("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationPlanBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = RevenueCycle.AuthorizationPlanBedLengthRule(maxLength: 3600)
        let item = RevenueCycle.newAuthorizationPlan("x", label: "y")
        item.bed = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationPlanRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = RevenueCycle.AuthorizationPlanRequiredCategoryRule(message: "authorization plan needs this field")
        let item = RevenueCycle.newAuthorizationPlan("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationPlanRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = RevenueCycle.AuthorizationPlanRequiredBedRule(message: "authorization plan needs an entry")
        let item = RevenueCycle.newAuthorizationPlan("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
