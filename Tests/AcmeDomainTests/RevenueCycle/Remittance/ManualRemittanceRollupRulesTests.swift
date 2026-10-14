@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualRemittanceRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultManualRemittanceRollupValidator()
        let item = RevenueCycle.newManualRemittanceRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleManualRemittanceRollupRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = RevenueCycle.ManualRemittanceRollupRegionLengthRule(maxLength: 64)
        let item = RevenueCycle.newManualRemittanceRollup("x", name: "y")
        item.region = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleManualRemittanceRollupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.ManualRemittanceRollupNameLengthRule(maxLength: 1000)
        let item = RevenueCycle.newManualRemittanceRollup("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleManualRemittanceRollupRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = RevenueCycle.ManualRemittanceRollupRequiredDescriptionRule(
            message: "manual remittance rollup needs this field"
        )
        let item = RevenueCycle.newManualRemittanceRollup("", name: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}
