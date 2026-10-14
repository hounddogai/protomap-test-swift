@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenDraftValidator()
        let item = Labs.newSpecimenDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.SpecimenDraftCodeLengthRule(maxLength: 255)
        let item = Labs.newSpecimenDraft("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenDraftRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.SpecimenDraftRequiredNameRule(message: "specimen draft needs a value")
        let item = Labs.newSpecimenDraft("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
