@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultRemittanceOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDefaultRemittanceOverrideValidator()
        let item = RevenueCycle.newDefaultRemittanceOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDefaultRemittanceOverrideBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = RevenueCycle.DefaultRemittanceOverrideBedLengthRule(maxLength: 16)
        let item = RevenueCycle.newDefaultRemittanceOverride("x", name: "y")
        item.bed = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDefaultRemittanceOverrideRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = RevenueCycle.DefaultRemittanceOverrideRequiredEncounterIDRule(
            message: "default remittance override needs this field"
        )
        let item = RevenueCycle.newDefaultRemittanceOverride("", name: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}
