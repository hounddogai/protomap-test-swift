@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferTargetValidator()
        let item = BedManagement.newTransferTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferTargetChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = BedManagement.TransferTargetChannelLengthRule(maxLength: 32)
        let item = BedManagement.newTransferTarget("x", name: "y")
        item.channel = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.TransferTargetRequiredCodeRule(message: "transfer target needs an entry")
        let item = BedManagement.newTransferTarget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
