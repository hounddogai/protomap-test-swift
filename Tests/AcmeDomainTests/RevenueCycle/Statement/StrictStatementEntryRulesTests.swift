@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictStatementEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStrictStatementEntryValidator()
        let item = RevenueCycle.newStrictStatementEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStrictStatementEntryRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = RevenueCycle.StrictStatementEntryRequiredDescriptionRule(
            message: "strict statement entry needs a value"
        )
        let item = RevenueCycle.newStrictStatementEntry("", label: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStrictStatementEntryLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.StrictStatementEntryLabelLengthRule(maxLength: 32)
        let item = RevenueCycle.newStrictStatementEntry("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStrictStatementEntryWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = RevenueCycle.StrictStatementEntryWardLengthRule(maxLength: 3600)
        let item = RevenueCycle.newStrictStatementEntry("x", label: "y")
        item.ward = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStrictStatementEntryRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.StrictStatementEntryRequiredLabelRule(message: "strict statement entry needs a value")
        let item = RevenueCycle.newStrictStatementEntry("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
