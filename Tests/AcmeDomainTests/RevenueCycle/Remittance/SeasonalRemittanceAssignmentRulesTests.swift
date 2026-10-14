@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleSeasonalRemittanceAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultSeasonalRemittanceAssignmentValidator()
        let item = RevenueCycle.newSeasonalRemittanceAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleSeasonalRemittanceAssignmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.SeasonalRemittanceAssignmentRequiredLabelRule(
            message: "seasonal remittance assignment needs a value"
        )
        let item = RevenueCycle.newSeasonalRemittanceAssignment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleSeasonalRemittanceAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.SeasonalRemittanceAssignmentRequiredCodeRule(
            message: "seasonal remittance assignment needs an entry"
        )
        let item = RevenueCycle.newSeasonalRemittanceAssignment("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
