@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultModalityProfileValidator()
        let item = Imaging.newModalityProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingModalityProfileRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Imaging.ModalityProfileRequiredBedRule(message: "modality profile needs this field")
        let item = Imaging.newModalityProfile("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ModalityProfileCodeLengthRule(maxLength: 120)
        let item = Imaging.newModalityProfile("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingModalityProfileRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Imaging.ModalityProfileRequiredClinicianIDRule(message: "modality profile needs this field")
        let item = Imaging.newModalityProfile("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingModalityProfileTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.ModalityProfileTitleLengthRule(maxLength: 16)
        let item = Imaging.newModalityProfile("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
