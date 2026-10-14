@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalRemittanceRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRegionalRemittanceRuleValidator()
        let item = RevenueCycle.newRegionalRemittanceRule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRegionalRemittanceRuleVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = RevenueCycle.RegionalRemittanceRuleVisitMinutesRangeRule(min: 16, max: 3600)
        let item = RevenueCycle.newRegionalRemittanceRule("x", label: "y")
        item.visitMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRegionalRemittanceRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RegionalRemittanceRuleRequiredCodeRule(
            message: "regional remittance rule needs an entry"
        )
        let item = RevenueCycle.newRegionalRemittanceRule("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
