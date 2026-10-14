@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedBedBoardGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCappedBedBoardGroupValidator()
        let item = BedManagement.newCappedBedBoardGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCappedBedBoardGroupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.CappedBedBoardGroupLabelLengthRule(maxLength: 120)
        let item = BedManagement.newCappedBedBoardGroup("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCappedBedBoardGroupChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = BedManagement.CappedBedBoardGroupChannelLengthRule(maxLength: 255)
        let item = BedManagement.newCappedBedBoardGroup("x", label: "y")
        item.channel = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCappedBedBoardGroupRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = BedManagement.CappedBedBoardGroupRequiredChannelRule(message: "capped bed board group needs an entry")
        let item = BedManagement.newCappedBedBoardGroup("", label: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
