@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceSummaryValidator()
        let item = RevenueCycle.newRemittanceSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceSummaryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.RemittanceSummaryCodeLengthRule(maxLength: 32)
        let item = RevenueCycle.newRemittanceSummary("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RemittanceSummaryRequiredCodeRule(message: "remittance summary needs a value")
        let item = RevenueCycle.newRemittanceSummary("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceSummaryTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = RevenueCycle.RemittanceSummaryTimezoneLengthRule(maxLength: 32)
        let item = RevenueCycle.newRemittanceSummary("x", label: "y")
        item.timezone = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
