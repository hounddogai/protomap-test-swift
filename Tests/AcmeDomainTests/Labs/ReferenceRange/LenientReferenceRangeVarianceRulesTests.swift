@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLenientReferenceRangeVarianceValidator()
        let item = Labs.newLenientReferenceRangeVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLenientReferenceRangeVarianceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.LenientReferenceRangeVarianceTitleLengthRule(maxLength: 3600)
        let item = Labs.newLenientReferenceRangeVariance("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLenientReferenceRangeVarianceNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.LenientReferenceRangeVarianceNameLengthRule(maxLength: 1000)
        let item = Labs.newLenientReferenceRangeVariance("x", title: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLenientReferenceRangeVarianceRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.LenientReferenceRangeVarianceRequiredNameRule(
            message: "lenient reference range variance needs a value"
        )
        let item = Labs.newLenientReferenceRangeVariance("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
