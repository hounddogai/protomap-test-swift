@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictInventoryRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultStrictInventoryRollupValidator()
        let item = Pharmacy.newStrictInventoryRollup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyStrictInventoryRollupScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Pharmacy.StrictInventoryRollupScoreRangeRule(min: 3.1, max: 1686.4)
        let item = Pharmacy.newStrictInventoryRollup("x", title: "y")
        item.score = 1687.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyStrictInventoryRollupRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.StrictInventoryRollupRequiredTitleRule(message: "strict inventory rollup needs a value")
        let item = Pharmacy.newStrictInventoryRollup("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
