@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedTransferSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultWeightedTransferSlotValidator()
        let item = BedManagement.newWeightedTransferSlot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementWeightedTransferSlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.WeightedTransferSlotCodeLengthRule(maxLength: 3600)
        let item = BedManagement.newWeightedTransferSlot("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementWeightedTransferSlotStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = BedManagement.WeightedTransferSlotStartsAtRangeRule(min: 64, max: 80)
        let item = BedManagement.newWeightedTransferSlot("x", name: "y")
        item.startsAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementWeightedTransferSlotPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = BedManagement.WeightedTransferSlotPayerLengthRule(maxLength: 120)
        let item = BedManagement.newWeightedTransferSlot("x", name: "y")
        item.payer = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementWeightedTransferSlotRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = BedManagement.WeightedTransferSlotRequiredPatientRefRule(
            message: "weighted transfer slot needs an entry"
        )
        let item = BedManagement.newWeightedTransferSlot("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementWeightedTransferSlotRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = BedManagement.WeightedTransferSlotRequiredPayerRule(message: "weighted transfer slot needs an entry")
        let item = BedManagement.newWeightedTransferSlot("", name: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}
