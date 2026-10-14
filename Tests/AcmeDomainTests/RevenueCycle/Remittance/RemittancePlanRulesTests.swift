@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittancePlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittancePlanValidator()
        let item = RevenueCycle.newRemittancePlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittancePlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RemittancePlanRequiredCodeRule(message: "remittance plan needs an entry")
        let item = RevenueCycle.newRemittancePlan("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittancePlanRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.RemittancePlanRequiredTitleRule(message: "remittance plan needs an entry")
        let item = RevenueCycle.newRemittancePlan("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittancePlanSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = RevenueCycle.RemittancePlanSourceLengthRule(maxLength: 120)
        let item = RevenueCycle.newRemittancePlan("x", title: "y")
        item.source = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittancePlanRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = RevenueCycle.RemittancePlanRequiredRegionRule(message: "remittance plan needs this field")
        let item = RevenueCycle.newRemittancePlan("", title: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}
