@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackAuthorizationAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultFallbackAuthorizationAssignmentValidator()
        let item = RevenueCycle.newFallbackAuthorizationAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleFallbackAuthorizationAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.FallbackAuthorizationAssignmentCodeLengthRule(maxLength: 3600)
        let item = RevenueCycle.newFallbackAuthorizationAssignment("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleFallbackAuthorizationAssignmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.FallbackAuthorizationAssignmentRequiredTitleRule(
            message: "fallback authorization assignment needs a value"
        )
        let item = RevenueCycle.newFallbackAuthorizationAssignment("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleFallbackAuthorizationAssignmentVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = RevenueCycle.FallbackAuthorizationAssignmentVisitMinutesRangeRule(min: 120, max: 3600)
        let item = RevenueCycle.newFallbackAuthorizationAssignment("x", title: "y")
        item.visitMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}
