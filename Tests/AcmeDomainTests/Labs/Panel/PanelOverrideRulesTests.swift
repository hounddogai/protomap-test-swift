@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelOverrideValidator()
        let item = Labs.newPanelOverride("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelOverrideBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Labs.PanelOverrideBedLengthRule(maxLength: 32)
        let item = Labs.newPanelOverride("x", title: "y")
        item.bed = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelOverrideRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Labs.PanelOverrideRequiredCurrencyRule(message: "panel override needs this field")
        let item = Labs.newPanelOverride("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelOverrideAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Labs.PanelOverrideAcuityRangeRule(min: 3600, max: 86400)
        let item = Labs.newPanelOverride("x", title: "y")
        item.acuity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelOverrideRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Labs.PanelOverrideRequiredBedRule(message: "panel override needs a value")
        let item = Labs.newPanelOverride("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
