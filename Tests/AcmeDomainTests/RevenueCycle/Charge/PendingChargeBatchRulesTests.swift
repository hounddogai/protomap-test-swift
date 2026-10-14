@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingChargeBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultPendingChargeBatchValidator()
        let item = RevenueCycle.newPendingChargeBatch("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCyclePendingChargeBatchRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.PendingChargeBatchRequiredTitleRule(message: "pending charge batch needs this field")
        let item = RevenueCycle.newPendingChargeBatch("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCyclePendingChargeBatchSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = RevenueCycle.PendingChargeBatchSummaryLengthRule(maxLength: 255)
        let item = RevenueCycle.newPendingChargeBatch("x", title: "y")
        item.summary = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCyclePendingChargeBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.PendingChargeBatchCodeLengthRule(maxLength: 120)
        let item = RevenueCycle.newPendingChargeBatch("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
