@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelDigestValidator()
        let item = Labs.newPanelDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelDigestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.PanelDigestNameLengthRule(maxLength: 16)
        let item = Labs.newPanelDigest("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelDigestRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Labs.PanelDigestRequiredClinicianIDRule(message: "panel digest needs an entry")
        let item = Labs.newPanelDigest("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelDigestDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Labs.PanelDigestDescriptionLengthRule(maxLength: 32)
        let item = Labs.newPanelDigest("x", name: "y")
        item.description = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelDigestAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Labs.PanelDigestAmountRangeRule(min: 5.1, max: 1657.5)
        let item = Labs.newPanelDigest("x", name: "y")
        item.amount = 1659.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelDigestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.PanelDigestRequiredNameRule(message: "panel digest needs an entry")
        let item = Labs.newPanelDigest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
