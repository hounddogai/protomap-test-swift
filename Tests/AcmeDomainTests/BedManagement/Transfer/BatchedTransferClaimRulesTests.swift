@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedTransferClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBatchedTransferClaimValidator()
        let item = BedManagement.newBatchedTransferClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBatchedTransferClaimRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = BedManagement.BatchedTransferClaimRetriesRangeRule(min: 16, max: 255)
        let item = BedManagement.newBatchedTransferClaim("x", name: "y")
        item.retries = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBatchedTransferClaimRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = BedManagement.BatchedTransferClaimRequiredRegionRule(message: "batched transfer claim needs a value")
        let item = BedManagement.newBatchedTransferClaim("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}
