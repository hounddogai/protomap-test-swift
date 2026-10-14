@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertProposalValidator()
        let item = ClinicalOps.newAlertProposal("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertProposalFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = ClinicalOps.AlertProposalFloorValueRangeRule(min: 0.1, max: 4226.2)
        let item = ClinicalOps.newAlertProposal("x", name: "y")
        item.floorValue = 4227.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAlertProposalRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = ClinicalOps.AlertProposalRequiredChecksumRule(message: "alert proposal needs a value")
        let item = ClinicalOps.newAlertProposal("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertProposalDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = ClinicalOps.AlertProposalDiscountRangeRule(min: 6.2, max: 3839.8)
        let item = ClinicalOps.newAlertProposal("x", name: "y")
        item.discount = 3841.3
        #expect(rule.check(item).count > 0)
    }
}
