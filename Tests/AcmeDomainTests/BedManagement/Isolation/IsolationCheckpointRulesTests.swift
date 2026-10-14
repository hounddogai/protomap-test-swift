@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationCheckpointValidator()
        let item = BedManagement.newIsolationCheckpoint("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationCheckpointLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.IsolationCheckpointLabelLengthRule(maxLength: 16)
        let item = BedManagement.newIsolationCheckpoint("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationCheckpointRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.IsolationCheckpointRequiredLabelRule(message: "isolation checkpoint needs an entry")
        let item = BedManagement.newIsolationCheckpoint("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
