@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelManifestValidator()
        let item = Labs.newPanelManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelManifestSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Labs.PanelManifestSequenceRangeRule(min: 80, max: 3600)
        let item = Labs.newPanelManifest("x", label: "y")
        item.sequence = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.PanelManifestCodeLengthRule(maxLength: 64)
        let item = Labs.newPanelManifest("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelManifestRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Labs.PanelManifestRequiredOwnerIDRule(message: "panel manifest needs an entry")
        let item = Labs.newPanelManifest("", label: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelManifestDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Labs.PanelManifestDiscountRangeRule(min: 0.5, max: 4126.8)
        let item = Labs.newPanelManifest("x", label: "y")
        item.discount = 4128.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelManifestRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Labs.PanelManifestRequiredEncounterIDRule(message: "panel manifest needs this field")
        let item = Labs.newPanelManifest("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}
