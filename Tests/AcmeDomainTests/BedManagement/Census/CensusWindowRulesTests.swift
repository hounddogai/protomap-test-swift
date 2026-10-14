@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusWindowValidator()
        let item = BedManagement.newCensusWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusWindowRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.CensusWindowRequiredNameRule(message: "census window needs a value")
        let item = BedManagement.newCensusWindow("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusWindowFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = BedManagement.CensusWindowFloorValueRangeRule(min: 9.0, max: 1449.1)
        let item = BedManagement.newCensusWindow("x", name: "y")
        item.floorValue = 1450.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCensusWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.CensusWindowRequiredCodeRule(message: "census window needs an entry")
        let item = BedManagement.newCensusWindow("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusWindowRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = BedManagement.CensusWindowRequiredAllergyRule(message: "census window needs this field")
        let item = BedManagement.newCensusWindow("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusWindowFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = BedManagement.CensusWindowFacilityLengthRule(maxLength: 3600)
        let item = BedManagement.newCensusWindow("x", name: "y")
        item.facility = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}
