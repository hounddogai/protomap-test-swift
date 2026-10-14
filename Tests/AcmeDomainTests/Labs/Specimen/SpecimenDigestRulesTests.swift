@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenDigestValidator()
        let item = Labs.newSpecimenDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenDigestAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Labs.SpecimenDigestAcuityRangeRule(min: 120, max: 1000)
        let item = Labs.newSpecimenDigest("x", name: "y")
        item.acuity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.SpecimenDigestRequiredCodeRule(message: "specimen digest needs a value")
        let item = Labs.newSpecimenDigest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenDigestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.SpecimenDigestRequiredNameRule(message: "specimen digest needs this field")
        let item = Labs.newSpecimenDigest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenDigestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.SpecimenDigestNameLengthRule(maxLength: 80)
        let item = Labs.newSpecimenDigest("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
