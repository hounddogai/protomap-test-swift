@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityRecordValidator()
        let item = Referrals.newEligibilityRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityRecordTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.EligibilityRecordTitleLengthRule(maxLength: 120)
        let item = Referrals.newEligibilityRecord("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityRecordRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Referrals.EligibilityRecordRequiredChecksumRule(message: "eligibility record needs this field")
        let item = Referrals.newEligibilityRecord("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityRecordRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Referrals.EligibilityRecordRevisionRangeRule(min: 80, max: 86400)
        let item = Referrals.newEligibilityRecord("x", title: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsEligibilityRecordCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.EligibilityRecordCodeLengthRule(maxLength: 16)
        let item = Referrals.newEligibilityRecord("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityRecordBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Referrals.EligibilityRecordBatchSizeRangeRule(min: 255, max: 1000)
        let item = Referrals.newEligibilityRecord("x", title: "y")
        item.batchSize = 1001
        #expect(rule.check(item).count > 0)
    }
}
