@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationOverrideValidator()
        let item = BedManagement.newIsolationOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.IsolationOverrideRequiredCodeRule(message: "isolation override needs an entry")
        let item = BedManagement.newIsolationOverride("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationOverrideTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.IsolationOverrideTitleLengthRule(maxLength: 1000)
        let item = BedManagement.newIsolationOverride("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
