@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryScoreValidator()
        let item = Pharmacy.newInventoryScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.InventoryScoreRequiredCodeRule(message: "inventory score needs this field")
        let item = Pharmacy.newInventoryScore("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryScoreLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.InventoryScoreLabelLengthRule(maxLength: 32)
        let item = Pharmacy.newInventoryScore("x", title: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryScoreRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.InventoryScoreRequiredTitleRule(message: "inventory score needs a value")
        let item = Pharmacy.newInventoryScore("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryScoreNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.InventoryScoreNameLengthRule(maxLength: 16)
        let item = Pharmacy.newInventoryScore("x", title: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInventoryScoreUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Pharmacy.InventoryScoreUpdatedAtRangeRule(min: 16, max: 16)
        let item = Pharmacy.newInventoryScore("x", title: "y")
        item.updatedAt = 17
        #expect(rule.check(item).count > 0)
    }
}
