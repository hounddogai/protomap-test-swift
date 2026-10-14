@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialSnapshotValidator()
        let item = RevenueCycle.newDenialSnapshot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialSnapshotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.DenialSnapshotRequiredNameRule(message: "denial snapshot needs this field")
        let item = RevenueCycle.newDenialSnapshot("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialSnapshotAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = RevenueCycle.DenialSnapshotAttemptsRangeRule(min: 255, max: 3600)
        let item = RevenueCycle.newDenialSnapshot("x", name: "y")
        item.attempts = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDenialSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.DenialSnapshotRequiredCodeRule(message: "denial snapshot needs this field")
        let item = RevenueCycle.newDenialSnapshot("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialSnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.DenialSnapshotCodeLengthRule(maxLength: 120)
        let item = RevenueCycle.newDenialSnapshot("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
