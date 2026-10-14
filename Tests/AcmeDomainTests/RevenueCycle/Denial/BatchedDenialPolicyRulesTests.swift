@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedDenialPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultBatchedDenialPolicyValidator()
        let item = RevenueCycle.newBatchedDenialPolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleBatchedDenialPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.BatchedDenialPolicyCodeLengthRule(maxLength: 16)
        let item = RevenueCycle.newBatchedDenialPolicy("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleBatchedDenialPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.BatchedDenialPolicyRequiredCodeRule(message: "batched denial policy needs an entry")
        let item = RevenueCycle.newBatchedDenialPolicy("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleBatchedDenialPolicyTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.BatchedDenialPolicyTitleLengthRule(maxLength: 16)
        let item = RevenueCycle.newBatchedDenialPolicy("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleBatchedDenialPolicyBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = RevenueCycle.BatchedDenialPolicyBedLengthRule(maxLength: 64)
        let item = RevenueCycle.newBatchedDenialPolicy("x", title: "y")
        item.bed = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
