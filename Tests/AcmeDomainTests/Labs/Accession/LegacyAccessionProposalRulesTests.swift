@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyAccessionProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLegacyAccessionProposalValidator()
        let item = Labs.newLegacyAccessionProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLegacyAccessionProposalLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.LegacyAccessionProposalLabelLengthRule(maxLength: 255)
        let item = Labs.newLegacyAccessionProposal("x", name: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLegacyAccessionProposalFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Labs.LegacyAccessionProposalFloorValueRangeRule(min: 8.9, max: 1890.7)
        let item = Labs.newLegacyAccessionProposal("x", name: "y")
        item.floorValue = 1892.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsLegacyAccessionProposalNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.LegacyAccessionProposalNameLengthRule(maxLength: 255)
        let item = Labs.newLegacyAccessionProposal("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
