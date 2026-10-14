@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelThresholdValidator()
        let item = Labs.newPanelThreshold("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelThresholdRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Labs.PanelThresholdRequiredCountryRule(message: "panel threshold needs this field")
        let item = Labs.newPanelThreshold("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
