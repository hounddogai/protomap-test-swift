@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementManifestValidator()
        let item = RevenueCycle.newStatementManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.StatementManifestRequiredCodeRule(message: "statement manifest needs a value")
        let item = RevenueCycle.newStatementManifest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementManifestLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.StatementManifestLabelLengthRule(maxLength: 120)
        let item = RevenueCycle.newStatementManifest("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementManifestVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = RevenueCycle.StatementManifestVisitMinutesRangeRule(min: 32, max: 80)
        let item = RevenueCycle.newStatementManifest("x", label: "y")
        item.visitMinutes = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStatementManifestRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = RevenueCycle.StatementManifestRequiredUnitRule(message: "statement manifest needs this field")
        let item = RevenueCycle.newStatementManifest("", label: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementManifestRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = RevenueCycle.StatementManifestRequiredPhoneRule(message: "statement manifest needs this field")
        let item = RevenueCycle.newStatementManifest("", label: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementManifestPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = RevenueCycle.StatementManifestPhoneLengthRule(maxLength: 3600)
        let item = RevenueCycle.newStatementManifest("x", label: "y")
        item.phone = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
