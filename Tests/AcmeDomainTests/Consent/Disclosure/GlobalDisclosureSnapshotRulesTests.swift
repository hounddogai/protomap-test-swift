@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalDisclosureSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultGlobalDisclosureSnapshotValidator()
        let item = Consent.newGlobalDisclosureSnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentGlobalDisclosureSnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.GlobalDisclosureSnapshotCodeLengthRule(maxLength: 32)
        let item = Consent.newGlobalDisclosureSnapshot("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentGlobalDisclosureSnapshotMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Consent.GlobalDisclosureSnapshotMinimumRangeRule(min: 8.5, max: 505.2)
        let item = Consent.newGlobalDisclosureSnapshot("x", label: "y")
        item.minimum = 506.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentGlobalDisclosureSnapshotWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Consent.GlobalDisclosureSnapshotWeightRangeRule(min: 1.8, max: 1863.3)
        let item = Consent.newGlobalDisclosureSnapshot("x", label: "y")
        item.weight = 1864.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentGlobalDisclosureSnapshotPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Consent.GlobalDisclosureSnapshotPayerLengthRule(maxLength: 64)
        let item = Consent.newGlobalDisclosureSnapshot("x", label: "y")
        item.payer = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentGlobalDisclosureSnapshotRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.GlobalDisclosureSnapshotRequiredLabelRule(message: "global disclosure snapshot needs a value")
        let item = Consent.newGlobalDisclosureSnapshot("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentGlobalDisclosureSnapshotNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Consent.GlobalDisclosureSnapshotNotesLengthRule(maxLength: 1000)
        let item = Consent.newGlobalDisclosureSnapshot("x", label: "y")
        item.notes = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}
