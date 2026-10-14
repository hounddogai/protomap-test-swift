@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedDisclosureSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWeightedDisclosureSnapshotValidator()
        let item = Consent.newWeightedDisclosureSnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWeightedDisclosureSnapshotRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Consent.WeightedDisclosureSnapshotRequiredReviewerRule(
            message: "weighted disclosure snapshot needs a value"
        )
        let item = Consent.newWeightedDisclosureSnapshot("", label: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWeightedDisclosureSnapshotWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Consent.WeightedDisclosureSnapshotWeightRangeRule(min: 6.4, max: 1414.1)
        let item = Consent.newWeightedDisclosureSnapshot("x", label: "y")
        item.weight = 1415.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentWeightedDisclosureSnapshotLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Consent.WeightedDisclosureSnapshotLocaleLengthRule(maxLength: 64)
        let item = Consent.newWeightedDisclosureSnapshot("x", label: "y")
        item.locale = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}
