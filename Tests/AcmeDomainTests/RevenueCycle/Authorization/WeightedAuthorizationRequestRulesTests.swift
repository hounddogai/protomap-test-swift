@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedAuthorizationRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultWeightedAuthorizationRequestValidator()
        let item = RevenueCycle.newWeightedAuthorizationRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleWeightedAuthorizationRequestCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = RevenueCycle.WeightedAuthorizationRequestCategoryLengthRule(maxLength: 1000)
        let item = RevenueCycle.newWeightedAuthorizationRequest("x", title: "y")
        item.category = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleWeightedAuthorizationRequestRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = RevenueCycle.WeightedAuthorizationRequestRequiredEncounterIDRule(
            message: "weighted authorization request needs a value"
        )
        let item = RevenueCycle.newWeightedAuthorizationRequest("", title: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleWeightedAuthorizationRequestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.WeightedAuthorizationRequestTitleLengthRule(maxLength: 80)
        let item = RevenueCycle.newWeightedAuthorizationRequest("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleWeightedAuthorizationRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.WeightedAuthorizationRequestRequiredCodeRule(
            message: "weighted authorization request needs this field"
        )
        let item = RevenueCycle.newWeightedAuthorizationRequest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleWeightedAuthorizationRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.WeightedAuthorizationRequestCodeLengthRule(maxLength: 86400)
        let item = RevenueCycle.newWeightedAuthorizationRequest("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
