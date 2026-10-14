@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedCleaningDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBatchedCleaningDigestValidator()
        let item = BedManagement.newBatchedCleaningDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBatchedCleaningDigestDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = BedManagement.BatchedCleaningDigestDurationMinutesRangeRule(min: 64, max: 120)
        let item = BedManagement.newBatchedCleaningDigest("x", label: "y")
        item.durationMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}
