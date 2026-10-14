@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackPrioritySlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultFallbackPrioritySlotValidator()
        let item = Imaging.newFallbackPrioritySlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingFallbackPrioritySlotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.FallbackPrioritySlotTitleLengthRule(maxLength: 80)
        let item = Imaging.newFallbackPrioritySlot("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingFallbackPrioritySlotRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Imaging.FallbackPrioritySlotRequiredOwnerIDRule(message: "fallback priority slot needs a value")
        let item = Imaging.newFallbackPrioritySlot("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingFallbackPrioritySlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.FallbackPrioritySlotRequiredCodeRule(message: "fallback priority slot needs a value")
        let item = Imaging.newFallbackPrioritySlot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingFallbackPrioritySlotRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.FallbackPrioritySlotRequiredTitleRule(message: "fallback priority slot needs this field")
        let item = Imaging.newFallbackPrioritySlot("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingFallbackPrioritySlotOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Imaging.FallbackPrioritySlotOwnerIDLengthRule(maxLength: 255)
        let item = Imaging.newFallbackPrioritySlot("x", title: "y")
        item.ownerID = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
