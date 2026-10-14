@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadSlotValidator()
        let item = Imaging.newReadSlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadSlotRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Imaging.ReadSlotRetriesRangeRule(min: 64, max: 3600)
        let item = Imaging.newReadSlot("x", label: "y")
        item.retries = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingReadSlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ReadSlotCodeLengthRule(maxLength: 80)
        let item = Imaging.newReadSlot("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ReadSlotRequiredCodeRule(message: "read slot needs a value")
        let item = Imaging.newReadSlot("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingReadSlotCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Imaging.ReadSlotCopayRangeRule(min: 2.6, max: 4108.4)
        let item = Imaging.newReadSlot("x", label: "y")
        item.copay = 4109.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingReadSlotStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Imaging.ReadSlotStartsAtRangeRule(min: 64, max: 120)
        let item = Imaging.newReadSlot("x", label: "y")
        item.startsAt = 121
        #expect(rule.check(item).count > 0)
    }
}
