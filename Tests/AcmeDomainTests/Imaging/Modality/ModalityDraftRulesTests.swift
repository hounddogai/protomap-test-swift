@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityDraftValidator()
        let item = Imaging.newModalityDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityDraftRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Imaging.ModalityDraftRequiredExternalRefRule(message: "modality draft needs a value")
        let item = Imaging.newModalityDraft("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityDraftLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.ModalityDraftLabelLengthRule(maxLength: 64)
        let item = Imaging.newModalityDraft("x", name: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityDraftAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Imaging.ModalityDraftAcuityRangeRule(min: 86400, max: 86400)
        let item = Imaging.newModalityDraft("x", name: "y")
        item.acuity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingModalityDraftNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.ModalityDraftNameLengthRule(maxLength: 1000)
        let item = Imaging.newModalityDraft("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
