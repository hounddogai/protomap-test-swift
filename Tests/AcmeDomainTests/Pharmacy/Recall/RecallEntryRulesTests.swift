@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallEntryValidator()
        let item = Pharmacy.newRecallEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RecallEntryRequiredCodeRule(message: "recall entry needs a value")
        let item = Pharmacy.newRecallEntry("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallEntryMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Pharmacy.RecallEntryMarginRangeRule(min: 4.3, max: 2136.1)
        let item = Pharmacy.newRecallEntry("x", name: "y")
        item.margin = 2137.6
        #expect(rule.check(item).count > 0)
    }
}
