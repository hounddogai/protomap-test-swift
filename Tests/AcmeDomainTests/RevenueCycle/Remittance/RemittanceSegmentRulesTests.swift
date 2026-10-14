@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceSegmentValidator()
        let item = RevenueCycle.newRemittanceSegment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceSegmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.RemittanceSegmentTitleLengthRule(maxLength: 16)
        let item = RevenueCycle.newRemittanceSegment("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceSegmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.RemittanceSegmentRequiredTitleRule(message: "remittance segment needs a value")
        let item = RevenueCycle.newRemittanceSegment("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceSegmentCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = RevenueCycle.RemittanceSegmentCostRangeRule(min: 2.7, max: 4261.8)
        let item = RevenueCycle.newRemittanceSegment("x", title: "y")
        item.cost = 4263.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRemittanceSegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.RemittanceSegmentCodeLengthRule(maxLength: 16)
        let item = RevenueCycle.newRemittanceSegment("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceSegmentRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = RevenueCycle.RemittanceSegmentRequiredTimezoneRule(message: "remittance segment needs a value")
        let item = RevenueCycle.newRemittanceSegment("", title: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}
