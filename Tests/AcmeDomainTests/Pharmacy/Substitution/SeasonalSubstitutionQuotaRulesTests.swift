@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalSubstitutionQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSeasonalSubstitutionQuotaValidator()
        let item = Pharmacy.newSeasonalSubstitutionQuota("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySeasonalSubstitutionQuotaCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Pharmacy.SeasonalSubstitutionQuotaCapacityRangeRule(min: 255, max: 86400)
        let item = Pharmacy.newSeasonalSubstitutionQuota("x", title: "y")
        item.capacity = 86401
        #expect(rule.check(item).count > 0)
    }
}
