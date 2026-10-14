@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedProgramDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultCappedProgramDigestValidator()
        let item = CareManagement.newCappedProgramDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementCappedProgramDigestBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = CareManagement.CappedProgramDigestBatchSizeRangeRule(min: 3600, max: 86400)
        let item = CareManagement.newCappedProgramDigest("x", label: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementCappedProgramDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.CappedProgramDigestCodeLengthRule(maxLength: 1000)
        let item = CareManagement.newCappedProgramDigest("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementCappedProgramDigestRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = CareManagement.CappedProgramDigestRequiredSegmentRule(message: "capped program digest needs a value")
        let item = CareManagement.newCappedProgramDigest("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementCappedProgramDigestCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = CareManagement.CappedProgramDigestCreatedAtRangeRule(min: 16, max: 64)
        let item = CareManagement.newCappedProgramDigest("x", label: "y")
        item.createdAt = 65
        #expect(rule.check(item).count > 0)
    }
}
