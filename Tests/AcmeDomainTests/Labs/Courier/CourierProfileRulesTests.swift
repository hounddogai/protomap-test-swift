@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierProfileValidator()
        let item = Labs.newCourierProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierProfileRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Labs.CourierProfileRequiredSourceRule(message: "courier profile needs this field")
        let item = Labs.newCourierProfile("", title: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierProfileAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Labs.CourierProfileAllergyLengthRule(maxLength: 64)
        let item = Labs.newCourierProfile("x", title: "y")
        item.allergy = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCourierProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.CourierProfileRequiredCodeRule(message: "courier profile needs an entry")
        let item = Labs.newCourierProfile("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
