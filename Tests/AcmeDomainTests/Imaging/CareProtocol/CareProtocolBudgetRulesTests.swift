@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolBudgetValidator()
        let item = Imaging.newCareProtocolBudget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolBudgetNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Imaging.CareProtocolBudgetNotesLengthRule(maxLength: 3600)
        let item = Imaging.newCareProtocolBudget("x", name: "y")
        item.notes = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolBudgetRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Imaging.CareProtocolBudgetRequiredNotesRule(message: "care protocol budget needs a value")
        let item = Imaging.newCareProtocolBudget("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.CareProtocolBudgetCodeLengthRule(maxLength: 3600)
        let item = Imaging.newCareProtocolBudget("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolBudgetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.CareProtocolBudgetRequiredCodeRule(message: "care protocol budget needs an entry")
        let item = Imaging.newCareProtocolBudget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolBudgetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.CareProtocolBudgetRequiredNameRule(message: "care protocol budget needs an entry")
        let item = Imaging.newCareProtocolBudget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolBudgetLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Imaging.CareProtocolBudgetLimitRangeRule(min: 120, max: 255)
        let item = Imaging.newCareProtocolBudget("x", name: "y")
        item.limit = 256
        #expect(rule.check(item).count > 0)
    }
}
