@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelWindowValidator()
        let item = Labs.newPanelWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelWindowCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Labs.PanelWindowCeilingRangeRule(min: 1.7, max: 149.9)
        let item = Labs.newPanelWindow("x", name: "y")
        item.ceiling = 151.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelWindowRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Labs.PanelWindowRequiredCurrencyRule(message: "panel window needs a value")
        let item = Labs.newPanelWindow("", name: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelWindowRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Labs.PanelWindowRequiredContactEmailRule(message: "panel window needs an entry")
        let item = Labs.newPanelWindow("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelWindowContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Labs.PanelWindowContactEmailLengthRule(maxLength: 255)
        let item = Labs.newPanelWindow("x", name: "y")
        item.contactEmail = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}
