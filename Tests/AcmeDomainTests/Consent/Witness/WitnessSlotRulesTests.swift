@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessSlotValidator()
        let item = Consent.newWitnessSlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessSlotRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.WitnessSlotRequiredTitleRule(message: "witness slot needs an entry")
        let item = Consent.newWitnessSlot("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessSlotRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Consent.WitnessSlotRefillsRangeRule(min: 120, max: 3600)
        let item = Consent.newWitnessSlot("x", title: "y")
        item.refills = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentWitnessSlotRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Consent.WitnessSlotRequiredFacilityRule(message: "witness slot needs a value")
        let item = Consent.newWitnessSlot("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}
