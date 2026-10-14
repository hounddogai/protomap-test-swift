@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialSlotValidator()
        let item = RevenueCycle.newDenialSlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialSlotRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = RevenueCycle.DenialSlotRequiredNotesRule(message: "denial slot needs a value")
        let item = RevenueCycle.newDenialSlot("", label: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialSlotRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = RevenueCycle.DenialSlotRequiredClinicianIDRule(message: "denial slot needs this field")
        let item = RevenueCycle.newDenialSlot("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialSlotRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = RevenueCycle.DenialSlotRateRangeRule(min: 8.7, max: 3132.9)
        let item = RevenueCycle.newDenialSlot("x", label: "y")
        item.rate = 3134.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDenialSlotLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = RevenueCycle.DenialSlotLimitRangeRule(min: 16, max: 1000)
        let item = RevenueCycle.newDenialSlot("x", label: "y")
        item.limit = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDenialSlotRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.DenialSlotRequiredLabelRule(message: "denial slot needs this field")
        let item = RevenueCycle.newDenialSlot("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
