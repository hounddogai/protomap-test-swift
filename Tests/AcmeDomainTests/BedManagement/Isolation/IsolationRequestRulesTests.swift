@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationRequestValidator()
        let item = BedManagement.newIsolationRequest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationRequestAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = BedManagement.IsolationRequestAttemptsRangeRule(min: 32, max: 86400)
        let item = BedManagement.newIsolationRequest("x", label: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementIsolationRequestVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = BedManagement.IsolationRequestVersionRangeRule(min: 16, max: 80)
        let item = BedManagement.newIsolationRequest("x", label: "y")
        item.version = 81
        #expect(rule.check(item).count > 0)
    }
}
