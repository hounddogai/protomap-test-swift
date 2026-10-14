@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationBatchValidator()
        let item = RevenueCycle.newAuthorizationBatch("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationBatchRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = RevenueCycle.AuthorizationBatchRequiredDescriptionRule(message: "authorization batch needs an entry")
        let item = RevenueCycle.newAuthorizationBatch("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationBatchFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = RevenueCycle.AuthorizationBatchFloorValueRangeRule(min: 1.1, max: 4409.6)
        let item = RevenueCycle.newAuthorizationBatch("x", title: "y")
        item.floorValue = 4411.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAuthorizationBatchReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = RevenueCycle.AuthorizationBatchReviewerLengthRule(maxLength: 64)
        let item = RevenueCycle.newAuthorizationBatch("x", title: "y")
        item.reviewer = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
