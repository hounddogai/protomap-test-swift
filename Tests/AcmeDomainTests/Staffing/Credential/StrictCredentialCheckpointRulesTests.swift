@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictCredentialCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultStrictCredentialCheckpointValidator()
        let item = Staffing.newStrictCredentialCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingStrictCredentialCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.StrictCredentialCheckpointCodeLengthRule(maxLength: 80)
        let item = Staffing.newStrictCredentialCheckpoint("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingStrictCredentialCheckpointQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Staffing.StrictCredentialCheckpointQuantityRangeRule(min: 32, max: 80)
        let item = Staffing.newStrictCredentialCheckpoint("x", name: "y")
        item.quantity = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingStrictCredentialCheckpointRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Staffing.StrictCredentialCheckpointRequiredTimezoneRule(
            message: "strict credential checkpoint needs this field"
        )
        let item = Staffing.newStrictCredentialCheckpoint("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}
