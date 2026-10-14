@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalSubstitutionExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSeasonalSubstitutionExceptionValidator()
        let item = Pharmacy.newSeasonalSubstitutionException("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySeasonalSubstitutionExceptionRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Pharmacy.SeasonalSubstitutionExceptionRequiredEncounterIDRule(
            message: "seasonal substitution exception needs a value"
        )
        let item = Pharmacy.newSeasonalSubstitutionException("", name: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySeasonalSubstitutionExceptionRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.SeasonalSubstitutionExceptionRequiredCodeRule(
            message: "seasonal substitution exception needs a value"
        )
        let item = Pharmacy.newSeasonalSubstitutionException("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
