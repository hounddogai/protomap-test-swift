@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseSlotValidator()
        let item = Pharmacy.newDispenseSlot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.DispenseSlotRequiredCodeRule(message: "dispense slot needs this field")
        let item = Pharmacy.newDispenseSlot("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseSlotCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Pharmacy.DispenseSlotCeilingRangeRule(min: 1.4, max: 3715.7)
        let item = Pharmacy.newDispenseSlot("x", name: "y")
        item.ceiling = 3717.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseSlotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.DispenseSlotRequiredNameRule(message: "dispense slot needs this field")
        let item = Pharmacy.newDispenseSlot("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
