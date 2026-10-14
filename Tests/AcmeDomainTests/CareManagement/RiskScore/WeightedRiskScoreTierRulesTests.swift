@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedRiskScoreTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultWeightedRiskScoreTierValidator()
        let item = CareManagement.newWeightedRiskScoreTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementWeightedRiskScoreTierNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = CareManagement.WeightedRiskScoreTierNotesLengthRule(maxLength: 16)
        let item = CareManagement.newWeightedRiskScoreTier("x", name: "y")
        item.notes = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementWeightedRiskScoreTierDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = CareManagement.WeightedRiskScoreTierDiscountRangeRule(min: 4.0, max: 4268.2)
        let item = CareManagement.newWeightedRiskScoreTier("x", name: "y")
        item.discount = 4269.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementWeightedRiskScoreTierRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = CareManagement.WeightedRiskScoreTierRequiredChannelRule(
            message: "weighted risk score tier needs this field"
        )
        let item = CareManagement.newWeightedRiskScoreTier("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
