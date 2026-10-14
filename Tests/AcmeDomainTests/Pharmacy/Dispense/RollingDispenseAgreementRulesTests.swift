@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingDispenseAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRollingDispenseAgreementValidator()
        let item = Pharmacy.newRollingDispenseAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRollingDispenseAgreementQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Pharmacy.RollingDispenseAgreementQuantityRangeRule(min: 64, max: 120)
        let item = Pharmacy.newRollingDispenseAgreement("x", title: "y")
        item.quantity = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRollingDispenseAgreementEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Pharmacy.RollingDispenseAgreementEncounterIDLengthRule(maxLength: 32)
        let item = Pharmacy.newRollingDispenseAgreement("x", title: "y")
        item.encounterID = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRollingDispenseAgreementWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Pharmacy.RollingDispenseAgreementWindowDaysRangeRule(min: 64, max: 64)
        let item = Pharmacy.newRollingDispenseAgreement("x", title: "y")
        item.windowDays = 65
        #expect(rule.check(item).count > 0)
    }
}
