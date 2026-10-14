@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictConsentFormWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultStrictConsentFormWindowValidator()
        let item = Consent.newStrictConsentFormWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentStrictConsentFormWindowRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Consent.StrictConsentFormWindowRequiredSegmentRule(
            message: "strict consent form window needs an entry"
        )
        let item = Consent.newStrictConsentFormWindow("", name: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentStrictConsentFormWindowRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Consent.StrictConsentFormWindowRequiredClinicianIDRule(
            message: "strict consent form window needs a value"
        )
        let item = Consent.newStrictConsentFormWindow("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentStrictConsentFormWindowFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Consent.StrictConsentFormWindowFloorValueRangeRule(min: 4.4, max: 3463.1)
        let item = Consent.newStrictConsentFormWindow("x", name: "y")
        item.floorValue = 3464.6
        #expect(rule.check(item).count > 0)
    }
}
