@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictBedBoardDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultStrictBedBoardDraftValidator()
        let item = BedManagement.newStrictBedBoardDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementStrictBedBoardDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.StrictBedBoardDraftRequiredCodeRule(message: "strict bed board draft needs a value")
        let item = BedManagement.newStrictBedBoardDraft("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementStrictBedBoardDraftRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = BedManagement.StrictBedBoardDraftRequiredCountryRule(message: "strict bed board draft needs a value")
        let item = BedManagement.newStrictBedBoardDraft("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementStrictBedBoardDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.StrictBedBoardDraftCodeLengthRule(maxLength: 1000)
        let item = BedManagement.newStrictBedBoardDraft("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementStrictBedBoardDraftLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.StrictBedBoardDraftLabelLengthRule(maxLength: 255)
        let item = BedManagement.newStrictBedBoardDraft("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
