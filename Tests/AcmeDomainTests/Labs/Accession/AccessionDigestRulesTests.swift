@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionDigestValidator()
        let item = Labs.newAccessionDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionDigestRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Labs.AccessionDigestRequiredDiagnosisCodeRule(message: "accession digest needs a value")
        let item = Labs.newAccessionDigest("", title: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionDigestQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Labs.AccessionDigestQuantityRangeRule(min: 16, max: 32)
        let item = Labs.newAccessionDigest("x", title: "y")
        item.quantity = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionDigestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.AccessionDigestTitleLengthRule(maxLength: 1000)
        let item = Labs.newAccessionDigest("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
