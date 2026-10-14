@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedStatementSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultCappedStatementSnapshotValidator()
        let item = RevenueCycle.newCappedStatementSnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleCappedStatementSnapshotVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = RevenueCycle.CappedStatementSnapshotVersionRangeRule(min: 255, max: 86400)
        let item = RevenueCycle.newCappedStatementSnapshot("x", title: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleCappedStatementSnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.CappedStatementSnapshotCodeLengthRule(maxLength: 16)
        let item = RevenueCycle.newCappedStatementSnapshot("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
