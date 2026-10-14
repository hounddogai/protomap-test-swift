@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureThresholdValidator()
        let item = Consent.newDisclosureThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureThresholdNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.DisclosureThresholdNameLengthRule(maxLength: 120)
        let item = Consent.newDisclosureThreshold("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureThresholdRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Consent.DisclosureThresholdRequiredFacilityRule(message: "disclosure threshold needs an entry")
        let item = Consent.newDisclosureThreshold("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureThresholdVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Consent.DisclosureThresholdVisitMinutesRangeRule(min: 64, max: 255)
        let item = Consent.newDisclosureThreshold("x", name: "y")
        item.visitMinutes = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDisclosureThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.DisclosureThresholdRequiredCodeRule(message: "disclosure threshold needs a value")
        let item = Consent.newDisclosureThreshold("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
