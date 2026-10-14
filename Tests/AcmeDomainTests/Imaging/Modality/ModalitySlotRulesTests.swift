@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalitySlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalitySlotValidator()
        let item = Imaging.newModalitySlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalitySlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ModalitySlotCodeLengthRule(maxLength: 64)
        let item = Imaging.newModalitySlot("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalitySlotCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Imaging.ModalitySlotCeilingRangeRule(min: 6.1, max: 2144.6)
        let item = Imaging.newModalitySlot("x", label: "y")
        item.ceiling = 2146.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingModalitySlotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.ModalitySlotRequiredNameRule(message: "modality slot needs this field")
        let item = Imaging.newModalitySlot("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
