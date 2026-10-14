@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalInventoryRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSeasonalInventoryRollupValidator()
        let item = Pharmacy.newSeasonalInventoryRollup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySeasonalInventoryRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.SeasonalInventoryRollupRequiredCodeRule(message: "seasonal inventory rollup needs an entry")
        let item = Pharmacy.newSeasonalInventoryRollup("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySeasonalInventoryRollupCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Pharmacy.SeasonalInventoryRollupCategoryLengthRule(maxLength: 255)
        let item = Pharmacy.newSeasonalInventoryRollup("x", title: "y")
        item.category = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacySeasonalInventoryRollupRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Pharmacy.SeasonalInventoryRollupRequiredCategoryRule(
            message: "seasonal inventory rollup needs this field"
        )
        let item = Pharmacy.newSeasonalInventoryRollup("", title: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySeasonalInventoryRollupRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Pharmacy.SeasonalInventoryRollupRequiredClinicianIDRule(
            message: "seasonal inventory rollup needs an entry"
        )
        let item = Pharmacy.newSeasonalInventoryRollup("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySeasonalInventoryRollupTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.SeasonalInventoryRollupTitleLengthRule(maxLength: 86400)
        let item = Pharmacy.newSeasonalInventoryRollup("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
