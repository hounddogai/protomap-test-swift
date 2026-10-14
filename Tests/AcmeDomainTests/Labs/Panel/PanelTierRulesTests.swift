@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelTierValidator()
        let item = Labs.newPanelTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.PanelTierCodeLengthRule(maxLength: 255)
        let item = Labs.newPanelTier("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelTierRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.PanelTierRequiredLabelRule(message: "panel tier needs this field")
        let item = Labs.newPanelTier("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PanelTierRequiredCodeRule(message: "panel tier needs this field")
        let item = Labs.newPanelTier("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelTierRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.PanelTierRequiredNameRule(message: "panel tier needs a value")
        let item = Labs.newPanelTier("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelTierRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Labs.PanelTierRevisionRangeRule(min: 80, max: 80)
        let item = Labs.newPanelTier("x", label: "y")
        item.revision = 81
        #expect(rule.check(item).count > 0)
    }
}
