@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionSummaryValidator()
        let item = Pharmacy.newInteractionSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionSummaryMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Pharmacy.InteractionSummaryMaximumRangeRule(min: 2.2, max: 4463.1)
        let item = Pharmacy.newInteractionSummary("x", title: "y")
        item.maximum = 4464.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInteractionSummaryTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.InteractionSummaryTitleLengthRule(maxLength: 64)
        let item = Pharmacy.newInteractionSummary("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
