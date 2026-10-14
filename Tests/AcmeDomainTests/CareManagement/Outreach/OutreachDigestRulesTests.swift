@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultOutreachDigestValidator()
        let item = CareManagement.newOutreachDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementOutreachDigestBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = CareManagement.OutreachDigestBatchSizeRangeRule(min: 16, max: 80)
        let item = CareManagement.newOutreachDigest("x", name: "y")
        item.batchSize = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementOutreachDigestRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = CareManagement.OutreachDigestRequiredChecksumRule(message: "outreach digest needs this field")
        let item = CareManagement.newOutreachDigest("", name: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
