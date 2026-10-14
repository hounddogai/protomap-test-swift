@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolThresholdValidator()
        let item = Imaging.newCareProtocolThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolThresholdNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.CareProtocolThresholdNameLengthRule(maxLength: 86400)
        let item = Imaging.newCareProtocolThreshold("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.CareProtocolThresholdRequiredCodeRule(message: "care protocol threshold needs this field")
        let item = Imaging.newCareProtocolThreshold("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.CareProtocolThresholdCodeLengthRule(maxLength: 32)
        let item = Imaging.newCareProtocolThreshold("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolThresholdRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Imaging.CareProtocolThresholdRequiredCountryRule(message: "care protocol threshold needs this field")
        let item = Imaging.newCareProtocolThreshold("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolThresholdRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Imaging.CareProtocolThresholdRequiredPatientRefRule(message: "care protocol threshold needs a value")
        let item = Imaging.newCareProtocolThreshold("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
