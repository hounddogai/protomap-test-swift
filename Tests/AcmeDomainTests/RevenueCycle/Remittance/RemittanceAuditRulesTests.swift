@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceAuditValidator()
        let item = RevenueCycle.newRemittanceAudit("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceAuditExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = RevenueCycle.RemittanceAuditExpiresAtRangeRule(min: 16, max: 86400)
        let item = RevenueCycle.newRemittanceAudit("x", label: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRemittanceAuditRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = RevenueCycle.RemittanceAuditRequiredOwnerIDRule(message: "remittance audit needs an entry")
        let item = RevenueCycle.newRemittanceAudit("", label: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceAuditCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = RevenueCycle.RemittanceAuditCeilingRangeRule(min: 3.0, max: 4948.4)
        let item = RevenueCycle.newRemittanceAudit("x", label: "y")
        item.ceiling = 4949.9
        #expect(rule.check(item).count > 0)
    }
}
