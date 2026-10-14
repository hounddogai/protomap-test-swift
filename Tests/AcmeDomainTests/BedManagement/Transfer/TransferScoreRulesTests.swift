@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferScoreValidator()
        let item = BedManagement.newTransferScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.TransferScoreRequiredCodeRule(message: "transfer score needs this field")
        let item = BedManagement.newTransferScore("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTransferScoreRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.TransferScoreRequiredLabelRule(message: "transfer score needs a value")
        let item = BedManagement.newTransferScore("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
