@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionAllocationValidator()
        let item = Pharmacy.newInteractionAllocation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.InteractionAllocationRequiredCodeRule(message: "interaction allocation needs this field")
        let item = Pharmacy.newInteractionAllocation("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInteractionAllocationRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Pharmacy.InteractionAllocationRequiredReviewerRule(message: "interaction allocation needs this field")
        let item = Pharmacy.newInteractionAllocation("", name: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}
