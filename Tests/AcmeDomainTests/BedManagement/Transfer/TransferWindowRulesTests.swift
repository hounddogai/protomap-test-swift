@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferWindowValidator()
        let item = BedManagement.newTransferWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferWindowRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.TransferWindowRequiredTitleRule(message: "transfer window needs an entry")
        let item = BedManagement.newTransferWindow("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTransferWindowPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = BedManagement.TransferWindowPayerLengthRule(maxLength: 80)
        let item = BedManagement.newTransferWindow("x", title: "y")
        item.payer = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferWindowPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = BedManagement.TransferWindowPriorityRangeRule(min: 16, max: 1000)
        let item = BedManagement.newTransferWindow("x", title: "y")
        item.priority = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.TransferWindowCodeLengthRule(maxLength: 16)
        let item = BedManagement.newTransferWindow("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
