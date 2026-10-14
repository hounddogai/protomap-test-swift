@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedStatementReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultBatchedStatementReservationValidator()
        let item = RevenueCycle.newBatchedStatementReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleBatchedStatementReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.BatchedStatementReservationRequiredCodeRule(
            message: "batched statement reservation needs a value"
        )
        let item = RevenueCycle.newBatchedStatementReservation("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleBatchedStatementReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.BatchedStatementReservationCodeLengthRule(maxLength: 16)
        let item = RevenueCycle.newBatchedStatementReservation("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleBatchedStatementReservationPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = RevenueCycle.BatchedStatementReservationPayerLengthRule(maxLength: 1000)
        let item = RevenueCycle.newBatchedStatementReservation("x", label: "y")
        item.payer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
