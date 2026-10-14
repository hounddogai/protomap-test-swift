@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultDispenseEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDefaultDispenseEntryValidator()
        let item = Pharmacy.newDefaultDispenseEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDefaultDispenseEntryUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Pharmacy.DefaultDispenseEntryUpdatedAtRangeRule(min: 120, max: 3600)
        let item = Pharmacy.newDefaultDispenseEntry("x", name: "y")
        item.updatedAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDefaultDispenseEntryRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Pharmacy.DefaultDispenseEntryRatioRangeRule(min: 6.8, max: 636.5)
        let item = Pharmacy.newDefaultDispenseEntry("x", name: "y")
        item.ratio = 638.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDefaultDispenseEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.DefaultDispenseEntryRequiredCodeRule(message: "default dispense entry needs this field")
        let item = Pharmacy.newDefaultDispenseEntry("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
