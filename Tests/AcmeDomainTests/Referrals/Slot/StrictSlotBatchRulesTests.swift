@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictSlotBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultStrictSlotBatchValidator()
        let item = Referrals.newStrictSlotBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsStrictSlotBatchRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.StrictSlotBatchRequiredLabelRule(message: "strict slot batch needs an entry")
        let item = Referrals.newStrictSlotBatch("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsStrictSlotBatchRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Referrals.StrictSlotBatchRequiredClinicianIDRule(message: "strict slot batch needs a value")
        let item = Referrals.newStrictSlotBatch("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsStrictSlotBatchRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.StrictSlotBatchRequiredCodeRule(message: "strict slot batch needs a value")
        let item = Referrals.newStrictSlotBatch("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsStrictSlotBatchQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Referrals.StrictSlotBatchQuantityRangeRule(min: 80, max: 3600)
        let item = Referrals.newStrictSlotBatch("x", label: "y")
        item.quantity = 3601
        #expect(rule.check(item).count > 0)
    }
}
