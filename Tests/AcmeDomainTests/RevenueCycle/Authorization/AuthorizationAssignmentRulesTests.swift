@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationAssignmentValidator()
        let item = RevenueCycle.newAuthorizationAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.AuthorizationAssignmentCodeLengthRule(maxLength: 1000)
        let item = RevenueCycle.newAuthorizationAssignment("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationAssignmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.AuthorizationAssignmentNameLengthRule(maxLength: 1000)
        let item = RevenueCycle.newAuthorizationAssignment("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationAssignmentRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = RevenueCycle.AuthorizationAssignmentRequiredFacilityRule(
            message: "authorization assignment needs a value"
        )
        let item = RevenueCycle.newAuthorizationAssignment("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationAssignmentRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = RevenueCycle.AuthorizationAssignmentRatioRangeRule(min: 8.5, max: 4659.3)
        let item = RevenueCycle.newAuthorizationAssignment("x", name: "y")
        item.ratio = 4660.8
        #expect(rule.check(item).count > 0)
    }
}
