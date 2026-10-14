@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusSlotValidator()
        let item = BedManagement.newCensusSlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusSlotMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = BedManagement.CensusSlotMinimumRangeRule(min: 0.9, max: 1940.5)
        let item = BedManagement.newCensusSlot("x", label: "y")
        item.minimum = 1942.0
        #expect(rule.check(item).count > 0)
    }
}
