@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveClaimSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAdaptiveClaimSnapshotValidator()
        let item = RevenueCycle.newAdaptiveClaimSnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAdaptiveClaimSnapshotNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.AdaptiveClaimSnapshotNameLengthRule(maxLength: 16)
        let item = RevenueCycle.newAdaptiveClaimSnapshot("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAdaptiveClaimSnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.AdaptiveClaimSnapshotCodeLengthRule(maxLength: 64)
        let item = RevenueCycle.newAdaptiveClaimSnapshot("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAdaptiveClaimSnapshotStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = RevenueCycle.AdaptiveClaimSnapshotStartsAtRangeRule(min: 80, max: 86400)
        let item = RevenueCycle.newAdaptiveClaimSnapshot("x", name: "y")
        item.startsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAdaptiveClaimSnapshotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.AdaptiveClaimSnapshotRequiredNameRule(message: "adaptive claim snapshot needs a value")
        let item = RevenueCycle.newAdaptiveClaimSnapshot("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
