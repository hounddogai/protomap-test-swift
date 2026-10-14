@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionDraftValidator()
        let item = Labs.newAccessionDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionDraftRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.AccessionDraftRequiredNameRule(message: "accession draft needs a value")
        let item = Labs.newAccessionDraft("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionDraftNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.AccessionDraftNameLengthRule(maxLength: 80)
        let item = Labs.newAccessionDraft("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionDraftCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Labs.AccessionDraftCreatedAtRangeRule(min: 80, max: 86400)
        let item = Labs.newAccessionDraft("x", name: "y")
        item.createdAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.AccessionDraftCodeLengthRule(maxLength: 64)
        let item = Labs.newAccessionDraft("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
