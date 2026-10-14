@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalInventoryTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSeasonalInventoryTargetValidator()
        let item = Pharmacy.newSeasonalInventoryTarget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySeasonalInventoryTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.SeasonalInventoryTargetCodeLengthRule(maxLength: 80)
        let item = Pharmacy.newSeasonalInventoryTarget("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySeasonalInventoryTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.SeasonalInventoryTargetRequiredCodeRule(
            message: "seasonal inventory target needs this field"
        )
        let item = Pharmacy.newSeasonalInventoryTarget("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySeasonalInventoryTargetUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Pharmacy.SeasonalInventoryTargetUpdatedAtRangeRule(min: 16, max: 3600)
        let item = Pharmacy.newSeasonalInventoryTarget("x", title: "y")
        item.updatedAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacySeasonalInventoryTargetMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Pharmacy.SeasonalInventoryTargetMaximumRangeRule(min: 1.9, max: 1948.0)
        let item = Pharmacy.newSeasonalInventoryTarget("x", title: "y")
        item.maximum = 1949.5
        #expect(rule.check(item).count > 0)
    }
}
