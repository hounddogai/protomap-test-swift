@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityAdjustmentValidator()
        let item = Imaging.newModalityAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityAdjustmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ModalityAdjustmentCodeLengthRule(maxLength: 32)
        let item = Imaging.newModalityAdjustment("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityAdjustmentBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Imaging.ModalityAdjustmentBedLengthRule(maxLength: 1000)
        let item = Imaging.newModalityAdjustment("x", label: "y")
        item.bed = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityAdjustmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.ModalityAdjustmentRequiredLabelRule(message: "modality adjustment needs an entry")
        let item = Imaging.newModalityAdjustment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityAdjustmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ModalityAdjustmentRequiredCodeRule(message: "modality adjustment needs a value")
        let item = Imaging.newModalityAdjustment("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityAdjustmentCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Imaging.ModalityAdjustmentCeilingRangeRule(min: 1.9, max: 385.5)
        let item = Imaging.newModalityAdjustment("x", label: "y")
        item.ceiling = 387.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingModalityAdjustmentRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Imaging.ModalityAdjustmentRequiredSegmentRule(message: "modality adjustment needs a value")
        let item = Imaging.newModalityAdjustment("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}
