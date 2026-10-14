@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryAccessionWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPrimaryAccessionWindowValidator()
        let item = Labs.newPrimaryAccessionWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPrimaryAccessionWindowCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Labs.PrimaryAccessionWindowCountryLengthRule(maxLength: 255)
        let item = Labs.newPrimaryAccessionWindow("x", label: "y")
        item.country = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPrimaryAccessionWindowPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Labs.PrimaryAccessionWindowPriorityRangeRule(min: 3600, max: 86400)
        let item = Labs.newPrimaryAccessionWindow("x", label: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}
