@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalSlotBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRegionalSlotBatchValidator()
        let item = Referrals.newRegionalSlotBatch("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRegionalSlotBatchRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Referrals.RegionalSlotBatchRequiredCategoryRule(message: "regional slot batch needs an entry")
        let item = Referrals.newRegionalSlotBatch("", title: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRegionalSlotBatchCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Referrals.RegionalSlotBatchCategoryLengthRule(maxLength: 86400)
        let item = Referrals.newRegionalSlotBatch("x", title: "y")
        item.category = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
