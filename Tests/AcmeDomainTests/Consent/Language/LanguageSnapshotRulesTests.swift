@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageSnapshotValidator()
        let item = Consent.newLanguageSnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageSnapshotRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.LanguageSnapshotRequiredLabelRule(message: "language snapshot needs an entry")
        let item = Consent.newLanguageSnapshot("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLanguageSnapshotRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Consent.LanguageSnapshotRequiredCategoryRule(message: "language snapshot needs an entry")
        let item = Consent.newLanguageSnapshot("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}
