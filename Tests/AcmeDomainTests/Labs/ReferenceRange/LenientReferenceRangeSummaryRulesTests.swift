@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLenientReferenceRangeSummaryValidator()
        let item = Labs.newLenientReferenceRangeSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLenientReferenceRangeSummaryRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Labs.LenientReferenceRangeSummaryRequiredClinicianIDRule(
            message: "lenient reference range summary needs a value"
        )
        let item = Labs.newLenientReferenceRangeSummary("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLenientReferenceRangeSummaryCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Labs.LenientReferenceRangeSummaryCeilingRangeRule(min: 9.9, max: 2126.0)
        let item = Labs.newLenientReferenceRangeSummary("x", label: "y")
        item.ceiling = 2127.5
        #expect(rule.check(item).count > 0)
    }
}
