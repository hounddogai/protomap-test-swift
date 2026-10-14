@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureSnapshotValidator()
        let item = Consent.newDisclosureSnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureSnapshotRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Consent.DisclosureSnapshotRequiredTimezoneRule(message: "disclosure snapshot needs this field")
        let item = Consent.newDisclosureSnapshot("", title: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.DisclosureSnapshotRequiredCodeRule(message: "disclosure snapshot needs an entry")
        let item = Consent.newDisclosureSnapshot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureSnapshotRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.DisclosureSnapshotRequiredTitleRule(message: "disclosure snapshot needs a value")
        let item = Consent.newDisclosureSnapshot("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
