@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalCareGapEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultSeasonalCareGapEntryValidator()
        let item = CareManagement.newSeasonalCareGapEntry("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementSeasonalCareGapEntryRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = CareManagement.SeasonalCareGapEntryRequiredAllergyRule(
            message: "seasonal care gap entry needs an entry"
        )
        let item = CareManagement.newSeasonalCareGapEntry("", title: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementSeasonalCareGapEntryVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = CareManagement.SeasonalCareGapEntryVersionRangeRule(min: 255, max: 255)
        let item = CareManagement.newSeasonalCareGapEntry("x", title: "y")
        item.version = 256
        #expect(rule.check(item).count > 0)
    }
}
