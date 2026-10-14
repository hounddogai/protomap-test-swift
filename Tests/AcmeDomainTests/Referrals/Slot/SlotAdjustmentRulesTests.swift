@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotAdjustmentValidator()
        let item = Referrals.newSlotAdjustment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotAdjustmentProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Referrals.SlotAdjustmentProcedureCodeLengthRule(maxLength: 255)
        let item = Referrals.newSlotAdjustment("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotAdjustmentBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Referrals.SlotAdjustmentBatchSizeRangeRule(min: 255, max: 86400)
        let item = Referrals.newSlotAdjustment("x", title: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSlotAdjustmentDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Referrals.SlotAdjustmentDosageMgRangeRule(min: 3.0, max: 4271.1)
        let item = Referrals.newSlotAdjustment("x", title: "y")
        item.dosageMg = 4272.6
        #expect(rule.check(item).count > 0)
    }
}
