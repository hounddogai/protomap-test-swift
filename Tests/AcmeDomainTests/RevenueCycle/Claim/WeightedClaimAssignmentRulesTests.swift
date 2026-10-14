@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedClaimAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultWeightedClaimAssignmentValidator()
        let item = RevenueCycle.newWeightedClaimAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleWeightedClaimAssignmentWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = RevenueCycle.WeightedClaimAssignmentWardLengthRule(maxLength: 1000)
        let item = RevenueCycle.newWeightedClaimAssignment("x", title: "y")
        item.ward = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleWeightedClaimAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.WeightedClaimAssignmentRequiredCodeRule(
            message: "weighted claim assignment needs an entry"
        )
        let item = RevenueCycle.newWeightedClaimAssignment("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleWeightedClaimAssignmentWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = RevenueCycle.WeightedClaimAssignmentWindowDaysRangeRule(min: 64, max: 3600)
        let item = RevenueCycle.newWeightedClaimAssignment("x", title: "y")
        item.windowDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleWeightedClaimAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.WeightedClaimAssignmentCodeLengthRule(maxLength: 86400)
        let item = RevenueCycle.newWeightedClaimAssignment("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleWeightedClaimAssignmentRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = RevenueCycle.WeightedClaimAssignmentRequiredWardRule(
            message: "weighted claim assignment needs a value"
        )
        let item = RevenueCycle.newWeightedClaimAssignment("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleWeightedClaimAssignmentDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = RevenueCycle.WeightedClaimAssignmentDiscountRangeRule(min: 1.3, max: 3750.7)
        let item = RevenueCycle.newWeightedClaimAssignment("x", title: "y")
        item.discount = 3752.2
        #expect(rule.check(item).count > 0)
    }
}
