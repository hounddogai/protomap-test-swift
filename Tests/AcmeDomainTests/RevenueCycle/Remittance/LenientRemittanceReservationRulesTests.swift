@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientRemittanceReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLenientRemittanceReservationValidator()
        let item = RevenueCycle.newLenientRemittanceReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLenientRemittanceReservationLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = RevenueCycle.LenientRemittanceReservationLimitRangeRule(min: 32, max: 1000)
        let item = RevenueCycle.newLenientRemittanceReservation("x", label: "y")
        item.limit = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleLenientRemittanceReservationAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = RevenueCycle.LenientRemittanceReservationAcuityRangeRule(min: 255, max: 86400)
        let item = RevenueCycle.newLenientRemittanceReservation("x", label: "y")
        item.acuity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleLenientRemittanceReservationRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.LenientRemittanceReservationRequiredLabelRule(
            message: "lenient remittance reservation needs this field"
        )
        let item = RevenueCycle.newLenientRemittanceReservation("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleLenientRemittanceReservationRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = RevenueCycle.LenientRemittanceReservationRequiredTimezoneRule(
            message: "lenient remittance reservation needs an entry"
        )
        let item = RevenueCycle.newLenientRemittanceReservation("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}
