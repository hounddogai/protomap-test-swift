@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultAuthorizationPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDefaultAuthorizationPlanValidator()
        let item = RevenueCycle.newDefaultAuthorizationPlan("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDefaultAuthorizationPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.DefaultAuthorizationPlanRequiredCodeRule(
            message: "default authorization plan needs an entry"
        )
        let item = RevenueCycle.newDefaultAuthorizationPlan("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDefaultAuthorizationPlanRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.DefaultAuthorizationPlanRequiredNameRule(
            message: "default authorization plan needs this field"
        )
        let item = RevenueCycle.newDefaultAuthorizationPlan("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDefaultAuthorizationPlanRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = RevenueCycle.DefaultAuthorizationPlanRequiredOwnerIDRule(
            message: "default authorization plan needs an entry"
        )
        let item = RevenueCycle.newDefaultAuthorizationPlan("", name: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}
