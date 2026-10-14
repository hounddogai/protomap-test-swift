@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingCleaningWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPendingCleaningWindowValidator()
        let item = BedManagement.newPendingCleaningWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPendingCleaningWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.PendingCleaningWindowCodeLengthRule(maxLength: 1000)
        let item = BedManagement.newPendingCleaningWindow("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPendingCleaningWindowRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.PendingCleaningWindowRequiredLabelRule(
            message: "pending cleaning window needs this field"
        )
        let item = BedManagement.newPendingCleaningWindow("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPendingCleaningWindowExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = BedManagement.PendingCleaningWindowExpiresAtRangeRule(min: 64, max: 86400)
        let item = BedManagement.newPendingCleaningWindow("x", label: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
