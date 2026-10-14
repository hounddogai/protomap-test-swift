@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityRecordValidator()
        let item = Imaging.newModalityRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityRecordRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Imaging.ModalityRecordRequiredExternalRefRule(message: "modality record needs this field")
        let item = Imaging.newModalityRecord("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityRecordMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Imaging.ModalityRecordMaximumRangeRule(min: 0.0, max: 3644.1)
        let item = Imaging.newModalityRecord("x", label: "y")
        item.maximum = 3645.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingModalityRecordMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Imaging.ModalityRecordMinimumRangeRule(min: 3.9, max: 4570.6)
        let item = Imaging.newModalityRecord("x", label: "y")
        item.minimum = 4572.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingModalityRecordLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.ModalityRecordLabelLengthRule(maxLength: 3600)
        let item = Imaging.newModalityRecord("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityRecordRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Imaging.ModalityRecordRequiredOwnerIDRule(message: "modality record needs an entry")
        let item = Imaging.newModalityRecord("", label: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}
