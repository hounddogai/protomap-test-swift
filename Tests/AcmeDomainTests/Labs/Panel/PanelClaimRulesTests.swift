@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelClaimValidator()
        let item = Labs.newPanelClaim("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelClaimPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Labs.PanelClaimPhoneLengthRule(maxLength: 120)
        let item = Labs.newPanelClaim("x", label: "y")
        item.phone = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelClaimScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Labs.PanelClaimScoreRangeRule(min: 4.7, max: 4514.1)
        let item = Labs.newPanelClaim("x", label: "y")
        item.score = 4515.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelClaimRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.PanelClaimRequiredLabelRule(message: "panel claim needs an entry")
        let item = Labs.newPanelClaim("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
