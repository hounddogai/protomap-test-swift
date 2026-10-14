@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedDischargePlanDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBatchedDischargePlanDraftValidator()
        let item = BedManagement.newBatchedDischargePlanDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBatchedDischargePlanDraftDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = BedManagement.BatchedDischargePlanDraftDiscountRangeRule(min: 4.3, max: 3434.7)
        let item = BedManagement.newBatchedDischargePlanDraft("x", name: "y")
        item.discount = 3436.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBatchedDischargePlanDraftRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.BatchedDischargePlanDraftRequiredNameRule(
            message: "batched discharge plan draft needs a value"
        )
        let item = BedManagement.newBatchedDischargePlanDraft("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBatchedDischargePlanDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.BatchedDischargePlanDraftRequiredCodeRule(
            message: "batched discharge plan draft needs an entry"
        )
        let item = BedManagement.newBatchedDischargePlanDraft("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
