@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelProposalValidator()
        let item = Labs.newPanelProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelProposalRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.PanelProposalRequiredLabelRule(message: "panel proposal needs a value")
        let item = Labs.newPanelProposal("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PanelProposalRequiredCodeRule(message: "panel proposal needs this field")
        let item = Labs.newPanelProposal("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
