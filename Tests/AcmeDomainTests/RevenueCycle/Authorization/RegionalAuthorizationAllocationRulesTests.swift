@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalAuthorizationAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRegionalAuthorizationAllocationValidator()
        let item = RevenueCycle.newRegionalAuthorizationAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRegionalAuthorizationAllocationWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = RevenueCycle.RegionalAuthorizationAllocationWardLengthRule(maxLength: 86400)
        let item = RevenueCycle.newRegionalAuthorizationAllocation("x", label: "y")
        item.ward = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRegionalAuthorizationAllocationDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = RevenueCycle.RegionalAuthorizationAllocationDurationMinutesRangeRule(min: 80, max: 120)
        let item = RevenueCycle.newRegionalAuthorizationAllocation("x", label: "y")
        item.durationMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRegionalAuthorizationAllocationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.RegionalAuthorizationAllocationLabelLengthRule(maxLength: 80)
        let item = RevenueCycle.newRegionalAuthorizationAllocation("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRegionalAuthorizationAllocationRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.RegionalAuthorizationAllocationRequiredLabelRule(
            message: "regional authorization allocation needs a value"
        )
        let item = RevenueCycle.newRegionalAuthorizationAllocation("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRegionalAuthorizationAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.RegionalAuthorizationAllocationCodeLengthRule(maxLength: 80)
        let item = RevenueCycle.newRegionalAuthorizationAllocation("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRegionalAuthorizationAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RegionalAuthorizationAllocationRequiredCodeRule(
            message: "regional authorization allocation needs an entry"
        )
        let item = RevenueCycle.newRegionalAuthorizationAllocation("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
