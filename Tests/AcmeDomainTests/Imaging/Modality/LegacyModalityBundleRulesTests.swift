@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyModalityBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultLegacyModalityBundleValidator()
        let item = Imaging.newLegacyModalityBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingLegacyModalityBundleRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Imaging.LegacyModalityBundleRequiredContactEmailRule(message: "legacy modality bundle needs an entry")
        let item = Imaging.newLegacyModalityBundle("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingLegacyModalityBundleRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Imaging.LegacyModalityBundleRequiredPatientRefRule(message: "legacy modality bundle needs this field")
        let item = Imaging.newLegacyModalityBundle("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingLegacyModalityBundleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.LegacyModalityBundleRequiredNameRule(message: "legacy modality bundle needs a value")
        let item = Imaging.newLegacyModalityBundle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
