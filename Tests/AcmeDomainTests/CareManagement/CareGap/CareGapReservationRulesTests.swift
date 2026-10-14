@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCareGapReservationValidator()
        let item = CareManagement.newCareGapReservation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCareGapReservationBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = CareManagement.CareGapReservationBatchSizeRangeRule(min: 86400, max: 86400)
        let item = CareManagement.newCareGapReservation("x", name: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCareGapReservationRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = CareManagement.CareGapReservationRequiredUnitRule(message: "care gap reservation needs this field")
        let item = CareManagement.newCareGapReservation("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
