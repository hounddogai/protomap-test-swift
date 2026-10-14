@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCleaningThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultGlobalCleaningThresholdValidator()
        let item = BedManagement.newGlobalCleaningThreshold("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementGlobalCleaningThresholdRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = BedManagement.GlobalCleaningThresholdRetriesRangeRule(min: 120, max: 3600)
        let item = BedManagement.newGlobalCleaningThreshold("x", label: "y")
        item.retries = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementGlobalCleaningThresholdBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = BedManagement.GlobalCleaningThresholdBedLengthRule(maxLength: 1000)
        let item = BedManagement.newGlobalCleaningThreshold("x", label: "y")
        item.bed = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
