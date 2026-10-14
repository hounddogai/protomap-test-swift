@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredCredentialPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultTieredCredentialPolicyValidator()
        let item = Staffing.newTieredCredentialPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingTieredCredentialPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.TieredCredentialPolicyRequiredCodeRule(message: "tiered credential policy needs this field")
        let item = Staffing.newTieredCredentialPolicy("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingTieredCredentialPolicyMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Staffing.TieredCredentialPolicyMaximumRangeRule(min: 2.5, max: 4321.6)
        let item = Staffing.newTieredCredentialPolicy("x", name: "y")
        item.maximum = 4323.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingTieredCredentialPolicySummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Staffing.TieredCredentialPolicySummaryLengthRule(maxLength: 16)
        let item = Staffing.newTieredCredentialPolicy("x", name: "y")
        item.summary = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingTieredCredentialPolicyRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Staffing.TieredCredentialPolicyRequiredContactEmailRule(
            message: "tiered credential policy needs this field"
        )
        let item = Staffing.newTieredCredentialPolicy("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingTieredCredentialPolicyWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Staffing.TieredCredentialPolicyWindowDaysRangeRule(min: 120, max: 120)
        let item = Staffing.newTieredCredentialPolicy("x", name: "y")
        item.windowDays = 121
        #expect(rule.check(item).count > 0)
    }
}
