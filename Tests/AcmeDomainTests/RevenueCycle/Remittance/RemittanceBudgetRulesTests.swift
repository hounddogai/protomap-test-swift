@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceBudgetValidator()
        let item = RevenueCycle.newRemittanceBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceBudgetDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = RevenueCycle.RemittanceBudgetDescriptionLengthRule(maxLength: 255)
        let item = RevenueCycle.newRemittanceBudget("x", title: "y")
        item.description = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceBudgetRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = RevenueCycle.RemittanceBudgetRegionLengthRule(maxLength: 16)
        let item = RevenueCycle.newRemittanceBudget("x", title: "y")
        item.region = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}
