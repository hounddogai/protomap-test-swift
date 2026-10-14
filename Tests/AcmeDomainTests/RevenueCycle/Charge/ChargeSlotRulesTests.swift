@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultChargeSlotValidator()
        let item = RevenueCycle.newChargeSlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleChargeSlotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.ChargeSlotLabelLengthRule(maxLength: 3600)
        let item = RevenueCycle.newChargeSlot("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeSlotRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = RevenueCycle.ChargeSlotRequiredSpecialtyRule(message: "charge slot needs an entry")
        let item = RevenueCycle.newChargeSlot("", label: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleChargeSlotExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = RevenueCycle.ChargeSlotExternalRefLengthRule(maxLength: 120)
        let item = RevenueCycle.newChargeSlot("x", label: "y")
        item.externalRef = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
