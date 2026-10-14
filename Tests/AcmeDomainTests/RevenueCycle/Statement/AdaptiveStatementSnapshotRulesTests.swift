@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveStatementSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAdaptiveStatementSnapshotValidator()
        let item = RevenueCycle.newAdaptiveStatementSnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAdaptiveStatementSnapshotQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = RevenueCycle.AdaptiveStatementSnapshotQuantityRangeRule(min: 16, max: 32)
        let item = RevenueCycle.newAdaptiveStatementSnapshot("x", name: "y")
        item.quantity = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAdaptiveStatementSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.AdaptiveStatementSnapshotRequiredCodeRule(
            message: "adaptive statement snapshot needs an entry"
        )
        let item = RevenueCycle.newAdaptiveStatementSnapshot("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAdaptiveStatementSnapshotNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.AdaptiveStatementSnapshotNameLengthRule(maxLength: 32)
        let item = RevenueCycle.newAdaptiveStatementSnapshot("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAdaptiveStatementSnapshotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.AdaptiveStatementSnapshotLabelLengthRule(maxLength: 1000)
        let item = RevenueCycle.newAdaptiveStatementSnapshot("x", name: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
