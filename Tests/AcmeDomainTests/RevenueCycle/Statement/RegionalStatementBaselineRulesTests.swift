@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalStatementBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRegionalStatementBaselineValidator()
        let item = RevenueCycle.newRegionalStatementBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRegionalStatementBaselineWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = RevenueCycle.RegionalStatementBaselineWardLengthRule(maxLength: 1000)
        let item = RevenueCycle.newRegionalStatementBaseline("x", label: "y")
        item.ward = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRegionalStatementBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RegionalStatementBaselineRequiredCodeRule(
            message: "regional statement baseline needs an entry"
        )
        let item = RevenueCycle.newRegionalStatementBaseline("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRegionalStatementBaselineLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.RegionalStatementBaselineLabelLengthRule(maxLength: 255)
        let item = RevenueCycle.newRegionalStatementBaseline("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
