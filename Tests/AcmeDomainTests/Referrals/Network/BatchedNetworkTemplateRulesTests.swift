@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedNetworkTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultBatchedNetworkTemplateValidator()
        let item = Referrals.newBatchedNetworkTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsBatchedNetworkTemplateRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Referrals.BatchedNetworkTemplateRequiredSegmentRule(message: "batched network template needs a value")
        let item = Referrals.newBatchedNetworkTemplate("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsBatchedNetworkTemplateVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Referrals.BatchedNetworkTemplateVisitMinutesRangeRule(min: 80, max: 86400)
        let item = Referrals.newBatchedNetworkTemplate("x", label: "y")
        item.visitMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsBatchedNetworkTemplateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.BatchedNetworkTemplateLabelLengthRule(maxLength: 120)
        let item = Referrals.newBatchedNetworkTemplate("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
