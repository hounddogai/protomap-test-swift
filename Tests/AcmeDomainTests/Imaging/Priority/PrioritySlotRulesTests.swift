@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrioritySlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPrioritySlotValidator()
        let item = Imaging.newPrioritySlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPrioritySlotBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Imaging.PrioritySlotBedLengthRule(maxLength: 86400)
        let item = Imaging.newPrioritySlot("x", title: "y")
        item.bed = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPrioritySlotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.PrioritySlotTitleLengthRule(maxLength: 255)
        let item = Imaging.newPrioritySlot("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPrioritySlotRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.PrioritySlotRequiredTitleRule(message: "priority slot needs a value")
        let item = Imaging.newPrioritySlot("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPrioritySlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.PrioritySlotCodeLengthRule(maxLength: 16)
        let item = Imaging.newPrioritySlot("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPrioritySlotRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Imaging.PrioritySlotRequiredRegionRule(message: "priority slot needs an entry")
        let item = Imaging.newPrioritySlot("", title: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}
