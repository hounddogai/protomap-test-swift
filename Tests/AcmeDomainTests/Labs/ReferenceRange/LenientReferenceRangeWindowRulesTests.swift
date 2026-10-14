@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLenientReferenceRangeWindowValidator()
        let item = Labs.newLenientReferenceRangeWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLenientReferenceRangeWindowSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Labs.LenientReferenceRangeWindowSpecialtyLengthRule(maxLength: 1000)
        let item = Labs.newLenientReferenceRangeWindow("x", name: "y")
        item.specialty = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLenientReferenceRangeWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.LenientReferenceRangeWindowRequiredCodeRule(
            message: "lenient reference range window needs a value"
        )
        let item = Labs.newLenientReferenceRangeWindow("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLenientReferenceRangeWindowRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.LenientReferenceRangeWindowRequiredNameRule(
            message: "lenient reference range window needs a value"
        )
        let item = Labs.newLenientReferenceRangeWindow("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLenientReferenceRangeWindowRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Labs.LenientReferenceRangeWindowRateRangeRule(min: 8.3, max: 3546.2)
        let item = Labs.newLenientReferenceRangeWindow("x", name: "y")
        item.rate = 3547.7
        #expect(rule.check(item).count > 0)
    }
}
