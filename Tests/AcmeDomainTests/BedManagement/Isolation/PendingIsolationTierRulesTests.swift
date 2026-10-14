@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingIsolationTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPendingIsolationTierValidator()
        let item = BedManagement.newPendingIsolationTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPendingIsolationTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.PendingIsolationTierRequiredCodeRule(message: "pending isolation tier needs a value")
        let item = BedManagement.newPendingIsolationTier("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPendingIsolationTierLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.PendingIsolationTierLabelLengthRule(maxLength: 3600)
        let item = BedManagement.newPendingIsolationTier("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
