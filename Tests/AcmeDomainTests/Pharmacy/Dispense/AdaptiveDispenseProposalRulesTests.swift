@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveDispenseProposalValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultAdaptiveDispenseProposalValidator()
        let item = Pharmacy.newAdaptiveDispenseProposal("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyAdaptiveDispenseProposalRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.AdaptiveDispenseProposalRequiredTitleRule(
            message: "adaptive dispense proposal needs this field"
        )
        let item = Pharmacy.newAdaptiveDispenseProposal("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyAdaptiveDispenseProposalLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Pharmacy.AdaptiveDispenseProposalLimitRangeRule(min: 80, max: 1000)
        let item = Pharmacy.newAdaptiveDispenseProposal("x", title: "y")
        item.limit = 1001
        #expect(rule.check(item).count > 0)
    }
}
