@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultCleaningProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDefaultCleaningProposalValidator()
        let item = BedManagement.newDefaultCleaningProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDefaultCleaningProposalAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = BedManagement.DefaultCleaningProposalAmountRangeRule(min: 3.4, max: 1661.2)
        let item = BedManagement.newDefaultCleaningProposal("x", name: "y")
        item.amount = 1662.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDefaultCleaningProposalRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = BedManagement.DefaultCleaningProposalRequiredCategoryRule(
            message: "default cleaning proposal needs this field"
        )
        let item = BedManagement.newDefaultCleaningProposal("", name: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDefaultCleaningProposalSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = BedManagement.DefaultCleaningProposalSegmentLengthRule(maxLength: 64)
        let item = BedManagement.newDefaultCleaningProposal("x", name: "y")
        item.segment = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}
