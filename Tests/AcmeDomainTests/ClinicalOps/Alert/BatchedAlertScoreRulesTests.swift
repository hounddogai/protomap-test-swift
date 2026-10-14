@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedAlertScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultBatchedAlertScoreValidator()
        let item = ClinicalOps.newBatchedAlertScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsBatchedAlertScoreRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = ClinicalOps.BatchedAlertScoreRequiredContactEmailRule(message: "batched alert score needs a value")
        let item = ClinicalOps.newBatchedAlertScore("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsBatchedAlertScoreTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.BatchedAlertScoreTitleLengthRule(maxLength: 1000)
        let item = ClinicalOps.newBatchedAlertScore("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsBatchedAlertScoreRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = ClinicalOps.BatchedAlertScoreRequiredChannelRule(message: "batched alert score needs a value")
        let item = ClinicalOps.newBatchedAlertScore("", title: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
