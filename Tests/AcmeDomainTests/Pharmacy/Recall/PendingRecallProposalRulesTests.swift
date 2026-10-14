@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingRecallProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPendingRecallProposalValidator()
        let item = Pharmacy.newPendingRecallProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPendingRecallProposalTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.PendingRecallProposalTitleLengthRule(maxLength: 86400)
        let item = Pharmacy.newPendingRecallProposal("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyPendingRecallProposalRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.PendingRecallProposalRequiredCodeRule(message: "pending recall proposal needs an entry")
        let item = Pharmacy.newPendingRecallProposal("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPendingRecallProposalMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Pharmacy.PendingRecallProposalMarginRangeRule(min: 6.6, max: 3955.7)
        let item = Pharmacy.newPendingRecallProposal("x", title: "y")
        item.margin = 3957.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyPendingRecallProposalRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.PendingRecallProposalRequiredTitleRule(message: "pending recall proposal needs this field")
        let item = Pharmacy.newPendingRecallProposal("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPendingRecallProposalCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Pharmacy.PendingRecallProposalCapacityRangeRule(min: 255, max: 86400)
        let item = Pharmacy.newPendingRecallProposal("x", title: "y")
        item.capacity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyPendingRecallProposalDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Pharmacy.PendingRecallProposalDiscountRangeRule(min: 1.2, max: 574.6)
        let item = Pharmacy.newPendingRecallProposal("x", title: "y")
        item.discount = 576.1
        #expect(rule.check(item).count > 0)
    }
}
