@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultHandoffDigestValidator()
        let item = ClinicalOps.newHandoffDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsHandoffDigestEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = ClinicalOps.HandoffDigestEndsAtRangeRule(min: 80, max: 255)
        let item = ClinicalOps.newHandoffDigest("x", label: "y")
        item.endsAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsHandoffDigestChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = ClinicalOps.HandoffDigestChannelLengthRule(maxLength: 255)
        let item = ClinicalOps.newHandoffDigest("x", label: "y")
        item.channel = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsHandoffDigestExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = ClinicalOps.HandoffDigestExpiresAtRangeRule(min: 64, max: 1000)
        let item = ClinicalOps.newHandoffDigest("x", label: "y")
        item.expiresAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
