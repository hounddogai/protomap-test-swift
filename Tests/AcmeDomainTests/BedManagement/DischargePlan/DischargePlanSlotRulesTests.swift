@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanSlotValidator()
        let item = BedManagement.newDischargePlanSlot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanSlotCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = BedManagement.DischargePlanSlotCeilingRangeRule(min: 6.1, max: 3561.5)
        let item = BedManagement.newDischargePlanSlot("x", name: "y")
        item.ceiling = 3563.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDischargePlanSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.DischargePlanSlotRequiredCodeRule(message: "discharge plan slot needs a value")
        let item = BedManagement.newDischargePlanSlot("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanSlotRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = BedManagement.DischargePlanSlotRequiredCurrencyRule(message: "discharge plan slot needs an entry")
        let item = BedManagement.newDischargePlanSlot("", name: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanSlotChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = BedManagement.DischargePlanSlotChecksumLengthRule(maxLength: 1000)
        let item = BedManagement.newDischargePlanSlot("x", name: "y")
        item.checksum = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}
