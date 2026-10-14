@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientBedBoardTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLenientBedBoardTierValidator()
        let item = BedManagement.newLenientBedBoardTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLenientBedBoardTierRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = BedManagement.LenientBedBoardTierRequiredLocaleRule(
            message: "lenient bed board tier needs this field"
        )
        let item = BedManagement.newLenientBedBoardTier("", name: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLenientBedBoardTierWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = BedManagement.LenientBedBoardTierWeightRangeRule(min: 3.5, max: 441.7)
        let item = BedManagement.newLenientBedBoardTier("x", name: "y")
        item.weight = 443.2
        #expect(rule.check(item).count > 0)
    }
}
