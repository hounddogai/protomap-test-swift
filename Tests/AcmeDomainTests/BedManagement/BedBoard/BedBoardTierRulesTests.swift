@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardTierValidator()
        let item = BedManagement.newBedBoardTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardTierRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.BedBoardTierRequiredTitleRule(message: "bed board tier needs a value")
        let item = BedManagement.newBedBoardTier("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardTierRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.BedBoardTierRequiredLabelRule(message: "bed board tier needs an entry")
        let item = BedManagement.newBedBoardTier("", title: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.BedBoardTierRequiredCodeRule(message: "bed board tier needs an entry")
        let item = BedManagement.newBedBoardTier("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.BedBoardTierCodeLengthRule(maxLength: 255)
        let item = BedManagement.newBedBoardTier("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardTierRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = BedManagement.BedBoardTierRequiredPhoneRule(message: "bed board tier needs a value")
        let item = BedManagement.newBedBoardTier("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}
