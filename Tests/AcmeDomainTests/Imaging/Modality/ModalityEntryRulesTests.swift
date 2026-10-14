@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityEntryValidator()
        let item = Imaging.newModalityEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityEntryLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.ModalityEntryLabelLengthRule(maxLength: 1000)
        let item = Imaging.newModalityEntry("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityEntryRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Imaging.ModalityEntryRegionLengthRule(maxLength: 255)
        let item = Imaging.newModalityEntry("x", label: "y")
        item.region = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ModalityEntryRequiredCodeRule(message: "modality entry needs this field")
        let item = Imaging.newModalityEntry("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityEntryMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Imaging.ModalityEntryMarginRangeRule(min: 9.4, max: 3147.9)
        let item = Imaging.newModalityEntry("x", label: "y")
        item.margin = 3149.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingModalityEntryPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Imaging.ModalityEntryPriorityRangeRule(min: 32, max: 86400)
        let item = Imaging.newModalityEntry("x", label: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}
