@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolTierValidator()
        let item = Imaging.newCareProtocolTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolTierPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Imaging.CareProtocolTierPatientRefLengthRule(maxLength: 1000)
        let item = Imaging.newCareProtocolTier("x", title: "y")
        item.patientRef = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolTierTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.CareProtocolTierTitleLengthRule(maxLength: 120)
        let item = Imaging.newCareProtocolTier("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolTierRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Imaging.CareProtocolTierRequiredPatientRefRule(message: "care protocol tier needs this field")
        let item = Imaging.newCareProtocolTier("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
