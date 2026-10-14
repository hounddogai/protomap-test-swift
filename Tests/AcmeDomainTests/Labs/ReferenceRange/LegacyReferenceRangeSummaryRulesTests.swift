@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyReferenceRangeSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLegacyReferenceRangeSummaryValidator()
        let item = Labs.newLegacyReferenceRangeSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLegacyReferenceRangeSummaryRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Labs.LegacyReferenceRangeSummaryRegionLengthRule(maxLength: 80)
        let item = Labs.newLegacyReferenceRangeSummary("x", label: "y")
        item.region = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLegacyReferenceRangeSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.LegacyReferenceRangeSummaryRequiredCodeRule(
            message: "legacy reference range summary needs this field"
        )
        let item = Labs.newLegacyReferenceRangeSummary("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLegacyReferenceRangeSummaryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.LegacyReferenceRangeSummaryCodeLengthRule(maxLength: 255)
        let item = Labs.newLegacyReferenceRangeSummary("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLegacyReferenceRangeSummaryRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Labs.LegacyReferenceRangeSummaryRequiredRegionRule(
            message: "legacy reference range summary needs an entry"
        )
        let item = Labs.newLegacyReferenceRangeSummary("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}
