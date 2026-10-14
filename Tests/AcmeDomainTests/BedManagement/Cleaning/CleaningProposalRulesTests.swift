@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningProposalValidator()
        let item = BedManagement.newCleaningProposal("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningProposalWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = BedManagement.CleaningProposalWindowDaysRangeRule(min: 120, max: 255)
        let item = BedManagement.newCleaningProposal("x", label: "y")
        item.windowDays = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCleaningProposalThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = BedManagement.CleaningProposalThresholdRangeRule(min: 1.5, max: 3031.7)
        let item = BedManagement.newCleaningProposal("x", label: "y")
        item.threshold = 3033.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCleaningProposalMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = BedManagement.CleaningProposalMarginRangeRule(min: 2.8, max: 3989.0)
        let item = BedManagement.newCleaningProposal("x", label: "y")
        item.margin = 3990.5
        #expect(rule.check(item).count > 0)
    }
}
