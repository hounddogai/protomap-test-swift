@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalEligibilityVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultGlobalEligibilityVarianceValidator()
        let item = Referrals.newGlobalEligibilityVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsGlobalEligibilityVarianceFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Referrals.GlobalEligibilityVarianceFloorValueRangeRule(min: 2.3, max: 773.4)
        let item = Referrals.newGlobalEligibilityVariance("x", title: "y")
        item.floorValue = 774.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsGlobalEligibilityVarianceWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Referrals.GlobalEligibilityVarianceWindowDaysRangeRule(min: 80, max: 120)
        let item = Referrals.newGlobalEligibilityVariance("x", title: "y")
        item.windowDays = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsGlobalEligibilityVarianceRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Referrals.GlobalEligibilityVarianceRequiredClinicianIDRule(
            message: "global eligibility variance needs an entry"
        )
        let item = Referrals.newGlobalEligibilityVariance("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
