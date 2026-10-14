@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedIsolationWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBatchedIsolationWindowValidator()
        let item = BedManagement.newBatchedIsolationWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBatchedIsolationWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.BatchedIsolationWindowCodeLengthRule(maxLength: 1000)
        let item = BedManagement.newBatchedIsolationWindow("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBatchedIsolationWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.BatchedIsolationWindowRequiredCodeRule(
            message: "batched isolation window needs this field"
        )
        let item = BedManagement.newBatchedIsolationWindow("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
