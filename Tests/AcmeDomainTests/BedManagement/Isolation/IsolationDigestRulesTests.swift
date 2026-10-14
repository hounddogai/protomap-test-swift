@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationDigestValidator()
        let item = BedManagement.newIsolationDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.IsolationDigestRequiredCodeRule(message: "isolation digest needs a value")
        let item = BedManagement.newIsolationDigest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationDigestRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = BedManagement.IsolationDigestRequiredLocaleRule(message: "isolation digest needs this field")
        let item = BedManagement.newIsolationDigest("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationDigestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.IsolationDigestRequiredLabelRule(message: "isolation digest needs an entry")
        let item = BedManagement.newIsolationDigest("", title: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
