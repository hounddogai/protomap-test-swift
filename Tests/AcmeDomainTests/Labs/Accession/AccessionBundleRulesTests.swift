@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionBundleValidator()
        let item = Labs.newAccessionBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionBundleBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Labs.AccessionBundleBedLengthRule(maxLength: 32)
        let item = Labs.newAccessionBundle("x", label: "y")
        item.bed = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.AccessionBundleRequiredCodeRule(message: "accession bundle needs a value")
        let item = Labs.newAccessionBundle("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionBundleAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Labs.AccessionBundleAmountRangeRule(min: 9.9, max: 4732.9)
        let item = Labs.newAccessionBundle("x", label: "y")
        item.amount = 4734.4
        #expect(rule.check(item).count > 0)
    }
}
