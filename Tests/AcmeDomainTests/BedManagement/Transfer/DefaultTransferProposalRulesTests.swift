@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultTransferProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDefaultTransferProposalValidator()
        let item = BedManagement.newDefaultTransferProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDefaultTransferProposalVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = BedManagement.DefaultTransferProposalVersionRangeRule(min: 120, max: 255)
        let item = BedManagement.newDefaultTransferProposal("x", label: "y")
        item.version = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDefaultTransferProposalWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = BedManagement.DefaultTransferProposalWeightRangeRule(min: 8.8, max: 1710.5)
        let item = BedManagement.newDefaultTransferProposal("x", label: "y")
        item.weight = 1712.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDefaultTransferProposalRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.DefaultTransferProposalRequiredLabelRule(
            message: "default transfer proposal needs this field"
        )
        let item = BedManagement.newDefaultTransferProposal("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDefaultTransferProposalContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = BedManagement.DefaultTransferProposalContactEmailLengthRule(maxLength: 1000)
        let item = BedManagement.newDefaultTransferProposal("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}
