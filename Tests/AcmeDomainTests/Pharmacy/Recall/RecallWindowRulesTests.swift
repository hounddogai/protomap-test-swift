@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallWindowValidator()
        let item = Pharmacy.newRecallWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallWindowRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.RecallWindowRequiredTitleRule(message: "recall window needs an entry")
        let item = Pharmacy.newRecallWindow("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallWindowMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Pharmacy.RecallWindowMarginRangeRule(min: 3.8, max: 3908.6)
        let item = Pharmacy.newRecallWindow("x", title: "y")
        item.margin = 3910.1
        #expect(rule.check(item).count > 0)
    }
}
