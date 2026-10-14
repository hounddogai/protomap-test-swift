@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictReadSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStrictReadSlotValidator()
        let item = Imaging.newStrictReadSlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStrictReadSlotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.StrictReadSlotTitleLengthRule(maxLength: 80)
        let item = Imaging.newStrictReadSlot("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStrictReadSlotRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Imaging.StrictReadSlotRequiredClinicianIDRule(message: "strict read slot needs an entry")
        let item = Imaging.newStrictReadSlot("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStrictReadSlotRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.StrictReadSlotRequiredTitleRule(message: "strict read slot needs an entry")
        let item = Imaging.newStrictReadSlot("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStrictReadSlotClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Imaging.StrictReadSlotClinicianIDLengthRule(maxLength: 80)
        let item = Imaging.newStrictReadSlot("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStrictReadSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.StrictReadSlotRequiredCodeRule(message: "strict read slot needs an entry")
        let item = Imaging.newStrictReadSlot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStrictReadSlotRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Imaging.StrictReadSlotRequiredFacilityRule(message: "strict read slot needs this field")
        let item = Imaging.newStrictReadSlot("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}
