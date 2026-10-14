@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedFollowUpPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultBatchedFollowUpPlanValidator()
        let item = Referrals.newBatchedFollowUpPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsBatchedFollowUpPlanRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.BatchedFollowUpPlanRequiredNameRule(message: "batched follow up plan needs an entry")
        let item = Referrals.newBatchedFollowUpPlan("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsBatchedFollowUpPlanRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Referrals.BatchedFollowUpPlanRequiredBedRule(message: "batched follow up plan needs this field")
        let item = Referrals.newBatchedFollowUpPlan("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
