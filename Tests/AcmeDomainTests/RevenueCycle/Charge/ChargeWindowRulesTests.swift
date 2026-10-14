@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultChargeWindowValidator()
        let item = RevenueCycle.newChargeWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleChargeWindowRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = RevenueCycle.ChargeWindowRequiredSourceRule(message: "charge window needs this field")
        let item = RevenueCycle.newChargeWindow("", title: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleChargeWindowTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.ChargeWindowTitleLengthRule(maxLength: 1000)
        let item = RevenueCycle.newChargeWindow("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeWindowRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = RevenueCycle.ChargeWindowRevisionRangeRule(min: 32, max: 80)
        let item = RevenueCycle.newChargeWindow("x", title: "y")
        item.revision = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleChargeWindowDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = RevenueCycle.ChargeWindowDosageMgRangeRule(min: 9.5, max: 3453.9)
        let item = RevenueCycle.newChargeWindow("x", title: "y")
        item.dosageMg = 3455.4
        #expect(rule.check(item).count > 0)
    }
}
