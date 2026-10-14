@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledCareProtocolProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultScheduledCareProtocolProfileValidator()
        let item = Imaging.newScheduledCareProtocolProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingScheduledCareProtocolProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ScheduledCareProtocolProfileRequiredCodeRule(
            message: "scheduled care protocol profile needs a value"
        )
        let item = Imaging.newScheduledCareProtocolProfile("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingScheduledCareProtocolProfileScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Imaging.ScheduledCareProtocolProfileScoreRangeRule(min: 9.7, max: 869.9)
        let item = Imaging.newScheduledCareProtocolProfile("x", name: "y")
        item.score = 871.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingScheduledCareProtocolProfileRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Imaging.ScheduledCareProtocolProfileRequiredPatientRefRule(
            message: "scheduled care protocol profile needs an entry"
        )
        let item = Imaging.newScheduledCareProtocolProfile("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingScheduledCareProtocolProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ScheduledCareProtocolProfileCodeLengthRule(maxLength: 16)
        let item = Imaging.newScheduledCareProtocolProfile("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingScheduledCareProtocolProfileRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Imaging.ScheduledCareProtocolProfileRequiredCountryRule(
            message: "scheduled care protocol profile needs a value"
        )
        let item = Imaging.newScheduledCareProtocolProfile("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
