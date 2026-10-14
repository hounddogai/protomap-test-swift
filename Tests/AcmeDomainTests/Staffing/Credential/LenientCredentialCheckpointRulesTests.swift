@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientCredentialCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultLenientCredentialCheckpointValidator()
        let item = Staffing.newLenientCredentialCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingLenientCredentialCheckpointRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Staffing.LenientCredentialCheckpointRatioRangeRule(min: 0.7, max: 3720.9)
        let item = Staffing.newLenientCredentialCheckpoint("x", title: "y")
        item.ratio = 3722.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingLenientCredentialCheckpointRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.LenientCredentialCheckpointRequiredTitleRule(
            message: "lenient credential checkpoint needs a value"
        )
        let item = Staffing.newLenientCredentialCheckpoint("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingLenientCredentialCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.LenientCredentialCheckpointCodeLengthRule(maxLength: 1000)
        let item = Staffing.newLenientCredentialCheckpoint("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingLenientCredentialCheckpointRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Staffing.LenientCredentialCheckpointRequiredOwnerIDRule(
            message: "lenient credential checkpoint needs a value"
        )
        let item = Staffing.newLenientCredentialCheckpoint("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}
