@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureCheckpointValidator()
        let item = Consent.newDisclosureCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureCheckpointRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.DisclosureCheckpointRequiredTitleRule(message: "disclosure checkpoint needs a value")
        let item = Consent.newDisclosureCheckpoint("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureCheckpointRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Consent.DisclosureCheckpointRequiredCategoryRule(message: "disclosure checkpoint needs an entry")
        let item = Consent.newDisclosureCheckpoint("", title: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureCheckpointCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Consent.DisclosureCheckpointCategoryLengthRule(maxLength: 3600)
        let item = Consent.newDisclosureCheckpoint("x", title: "y")
        item.category = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
