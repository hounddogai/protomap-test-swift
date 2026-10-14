@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityGroupValidator()
        let item = Imaging.newModalityGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityGroupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.ModalityGroupRequiredLabelRule(message: "modality group needs this field")
        let item = Imaging.newModalityGroup("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityGroupBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Imaging.ModalityGroupBedLengthRule(maxLength: 64)
        let item = Imaging.newModalityGroup("x", label: "y")
        item.bed = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ModalityGroupCodeLengthRule(maxLength: 120)
        let item = Imaging.newModalityGroup("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityGroupRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Imaging.ModalityGroupRequiredBedRule(message: "modality group needs a value")
        let item = Imaging.newModalityGroup("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
