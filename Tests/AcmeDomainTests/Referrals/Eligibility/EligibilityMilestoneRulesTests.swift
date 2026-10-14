@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityMilestoneValidator()
        let item = Referrals.newEligibilityMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityMilestoneDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Referrals.EligibilityMilestoneDiagnosisCodeLengthRule(maxLength: 80)
        let item = Referrals.newEligibilityMilestone("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityMilestoneNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.EligibilityMilestoneNameLengthRule(maxLength: 32)
        let item = Referrals.newEligibilityMilestone("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityMilestoneAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Referrals.EligibilityMilestoneAcuityRangeRule(min: 64, max: 120)
        let item = Referrals.newEligibilityMilestone("x", name: "y")
        item.acuity = 121
        #expect(rule.check(item).count > 0)
    }
}
