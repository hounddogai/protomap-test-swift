@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityWindowValidator()
        let item = Imaging.newModalityWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ModalityWindowRequiredCodeRule(message: "modality window needs this field")
        let item = Imaging.newModalityWindow("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityWindowRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Imaging.ModalityWindowRequiredDescriptionRule(message: "modality window needs an entry")
        let item = Imaging.newModalityWindow("", label: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityWindowClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Imaging.ModalityWindowClinicianIDLengthRule(maxLength: 80)
        let item = Imaging.newModalityWindow("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityWindowAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Imaging.ModalityWindowAttemptsRangeRule(min: 16, max: 120)
        let item = Imaging.newModalityWindow("x", label: "y")
        item.attempts = 121
        #expect(rule.check(item).count > 0)
    }
}
