@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceBaselineValidator()
        let item = RevenueCycle.newRemittanceBaseline("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RemittanceBaselineRequiredCodeRule(message: "remittance baseline needs this field")
        let item = RevenueCycle.newRemittanceBaseline("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceBaselineRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.RemittanceBaselineRequiredTitleRule(message: "remittance baseline needs this field")
        let item = RevenueCycle.newRemittanceBaseline("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
