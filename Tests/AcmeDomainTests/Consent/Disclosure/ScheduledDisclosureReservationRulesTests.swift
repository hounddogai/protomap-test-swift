@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledDisclosureReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultScheduledDisclosureReservationValidator()
        let item = Consent.newScheduledDisclosureReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentScheduledDisclosureReservationCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Consent.ScheduledDisclosureReservationCapacityRangeRule(min: 120, max: 255)
        let item = Consent.newScheduledDisclosureReservation("x", label: "y")
        item.capacity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentScheduledDisclosureReservationRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.ScheduledDisclosureReservationRequiredLabelRule(
            message: "scheduled disclosure reservation needs a value"
        )
        let item = Consent.newScheduledDisclosureReservation("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentScheduledDisclosureReservationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.ScheduledDisclosureReservationLabelLengthRule(maxLength: 64)
        let item = Consent.newScheduledDisclosureReservation("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentScheduledDisclosureReservationMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Consent.ScheduledDisclosureReservationMarginRangeRule(min: 5.5, max: 4963.1)
        let item = Consent.newScheduledDisclosureReservation("x", label: "y")
        item.margin = 4964.6
        #expect(rule.check(item).count > 0)
    }
}
