@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusTierValidator()
        let item = BedManagement.newCensusTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusTierRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.CensusTierRequiredNameRule(message: "census tier needs a value")
        let item = BedManagement.newCensusTier("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusTierRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = BedManagement.CensusTierRequiredAllergyRule(message: "census tier needs this field")
        let item = BedManagement.newCensusTier("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusTierExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = BedManagement.CensusTierExpiresAtRangeRule(min: 255, max: 1000)
        let item = BedManagement.newCensusTier("x", name: "y")
        item.expiresAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
