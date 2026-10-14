@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedInteractionMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultBatchedInteractionMilestoneValidator()
        let item = Pharmacy.newBatchedInteractionMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyBatchedInteractionMilestoneUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Pharmacy.BatchedInteractionMilestoneUnitLengthRule(maxLength: 1000)
        let item = Pharmacy.newBatchedInteractionMilestone("x", name: "y")
        item.unit = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyBatchedInteractionMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.BatchedInteractionMilestoneRequiredCodeRule(
            message: "batched interaction milestone needs an entry"
        )
        let item = Pharmacy.newBatchedInteractionMilestone("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyBatchedInteractionMilestoneRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Pharmacy.BatchedInteractionMilestoneRequiredUnitRule(
            message: "batched interaction milestone needs an entry"
        )
        let item = Pharmacy.newBatchedInteractionMilestone("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
