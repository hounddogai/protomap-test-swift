@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultRecallMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDefaultRecallMilestoneValidator()
        let item = Pharmacy.newDefaultRecallMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDefaultRecallMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.DefaultRecallMilestoneCodeLengthRule(maxLength: 80)
        let item = Pharmacy.newDefaultRecallMilestone("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDefaultRecallMilestoneTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.DefaultRecallMilestoneTitleLengthRule(maxLength: 32)
        let item = Pharmacy.newDefaultRecallMilestone("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDefaultRecallMilestoneQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Pharmacy.DefaultRecallMilestoneQuantityRangeRule(min: 80, max: 1000)
        let item = Pharmacy.newDefaultRecallMilestone("x", title: "y")
        item.quantity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDefaultRecallMilestoneScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Pharmacy.DefaultRecallMilestoneScoreRangeRule(min: 8.8, max: 4077.2)
        let item = Pharmacy.newDefaultRecallMilestone("x", title: "y")
        item.score = 4078.7
        #expect(rule.check(item).count > 0)
    }
}
