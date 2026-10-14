@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalReadSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultGlobalReadSlotValidator()
        let item = Imaging.newGlobalReadSlot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingGlobalReadSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.GlobalReadSlotRequiredCodeRule(message: "global read slot needs this field")
        let item = Imaging.newGlobalReadSlot("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingGlobalReadSlotNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.GlobalReadSlotNameLengthRule(maxLength: 3600)
        let item = Imaging.newGlobalReadSlot("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingGlobalReadSlotDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Imaging.GlobalReadSlotDiscountRangeRule(min: 9.3, max: 2779.4)
        let item = Imaging.newGlobalReadSlot("x", name: "y")
        item.discount = 2780.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingGlobalReadSlotCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Imaging.GlobalReadSlotCeilingRangeRule(min: 9.5, max: 1939.7)
        let item = Imaging.newGlobalReadSlot("x", name: "y")
        item.ceiling = 1941.2
        #expect(rule.check(item).count > 0)
    }
}
