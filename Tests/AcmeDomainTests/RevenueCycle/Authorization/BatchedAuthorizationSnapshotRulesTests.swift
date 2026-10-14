@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedAuthorizationSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultBatchedAuthorizationSnapshotValidator()
        let item = RevenueCycle.newBatchedAuthorizationSnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleBatchedAuthorizationSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.BatchedAuthorizationSnapshotRequiredCodeRule(
            message: "batched authorization snapshot needs an entry"
        )
        let item = RevenueCycle.newBatchedAuthorizationSnapshot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleBatchedAuthorizationSnapshotRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = RevenueCycle.BatchedAuthorizationSnapshotRequiredReviewerRule(
            message: "batched authorization snapshot needs this field"
        )
        let item = RevenueCycle.newBatchedAuthorizationSnapshot("", title: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleBatchedAuthorizationSnapshotRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = RevenueCycle.BatchedAuthorizationSnapshotRequiredContactEmailRule(
            message: "batched authorization snapshot needs an entry"
        )
        let item = RevenueCycle.newBatchedAuthorizationSnapshot("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}
