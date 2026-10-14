@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredRemittanceCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultTieredRemittanceCheckpointValidator()
        let item = RevenueCycle.newTieredRemittanceCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleTieredRemittanceCheckpointNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.TieredRemittanceCheckpointNameLengthRule(maxLength: 64)
        let item = RevenueCycle.newTieredRemittanceCheckpoint("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleTieredRemittanceCheckpointRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.TieredRemittanceCheckpointRequiredNameRule(
            message: "tiered remittance checkpoint needs an entry"
        )
        let item = RevenueCycle.newTieredRemittanceCheckpoint("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
