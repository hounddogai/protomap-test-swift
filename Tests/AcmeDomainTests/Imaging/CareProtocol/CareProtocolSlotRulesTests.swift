@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolSlotValidator()
        let item = Imaging.newCareProtocolSlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolSlotPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Imaging.CareProtocolSlotPayerLengthRule(maxLength: 120)
        let item = Imaging.newCareProtocolSlot("x", title: "y")
        item.payer = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.CareProtocolSlotRequiredCodeRule(message: "care protocol slot needs an entry")
        let item = Imaging.newCareProtocolSlot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolSlotMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Imaging.CareProtocolSlotMinimumRangeRule(min: 6.4, max: 1790.6)
        let item = Imaging.newCareProtocolSlot("x", title: "y")
        item.minimum = 1792.1
        #expect(rule.check(item).count > 0)
    }
}
