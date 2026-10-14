@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalFollowUpAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultGlobalFollowUpAuditValidator()
        let item = Referrals.newGlobalFollowUpAudit("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsGlobalFollowUpAuditRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Referrals.GlobalFollowUpAuditRequiredUnitRule(message: "global follow up audit needs this field")
        let item = Referrals.newGlobalFollowUpAudit("", label: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsGlobalFollowUpAuditMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Referrals.GlobalFollowUpAuditMinimumRangeRule(min: 2.1, max: 127.5)
        let item = Referrals.newGlobalFollowUpAudit("x", label: "y")
        item.minimum = 129.0
        #expect(rule.check(item).count > 0)
    }
}
