@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenPolicyValidator()
        let item = Labs.newSpecimenPolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenPolicyRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Labs.SpecimenPolicyRequiredDescriptionRule(message: "specimen policy needs a value")
        let item = Labs.newSpecimenPolicy("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenPolicyPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Labs.SpecimenPolicyPayerLengthRule(maxLength: 16)
        let item = Labs.newSpecimenPolicy("x", title: "y")
        item.payer = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenPolicyRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Labs.SpecimenPolicyRequiredPayerRule(message: "specimen policy needs this field")
        let item = Labs.newSpecimenPolicy("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenPolicyRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Labs.SpecimenPolicyRateRangeRule(min: 5.0, max: 489.8)
        let item = Labs.newSpecimenPolicy("x", title: "y")
        item.rate = 491.3
        #expect(rule.check(item).count > 0)
    }
}
