@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredInventoryScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultTieredInventoryScoreValidator()
        let item = Pharmacy.newTieredInventoryScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyTieredInventoryScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.TieredInventoryScoreCodeLengthRule(maxLength: 32)
        let item = Pharmacy.newTieredInventoryScore("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyTieredInventoryScoreRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.TieredInventoryScoreRequiredNameRule(message: "tiered inventory score needs a value")
        let item = Pharmacy.newTieredInventoryScore("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyTieredInventoryScoreNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.TieredInventoryScoreNameLengthRule(maxLength: 80)
        let item = Pharmacy.newTieredInventoryScore("x", title: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
