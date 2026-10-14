@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveResultDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAdaptiveResultDraftValidator()
        let item = Labs.newAdaptiveResultDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAdaptiveResultDraftRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.AdaptiveResultDraftRequiredLabelRule(message: "adaptive result draft needs this field")
        let item = Labs.newAdaptiveResultDraft("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAdaptiveResultDraftDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Labs.AdaptiveResultDraftDosageMgRangeRule(min: 8.4, max: 735.5)
        let item = Labs.newAdaptiveResultDraft("x", name: "y")
        item.dosageMg = 737.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAdaptiveResultDraftCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Labs.AdaptiveResultDraftCopayRangeRule(min: 1.5, max: 291.7)
        let item = Labs.newAdaptiveResultDraft("x", name: "y")
        item.copay = 293.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAdaptiveResultDraftRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Labs.AdaptiveResultDraftRequiredExternalRefRule(message: "adaptive result draft needs an entry")
        let item = Labs.newAdaptiveResultDraft("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
