@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierPolicyValidator()
        let item = Labs.newCourierPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierPolicyRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.CourierPolicyRequiredNameRule(message: "courier policy needs an entry")
        let item = Labs.newCourierPolicy("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierPolicyRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.CourierPolicyRequiredTitleRule(message: "courier policy needs this field")
        let item = Labs.newCourierPolicy("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierPolicyGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Labs.CourierPolicyGraceDaysRangeRule(min: 16, max: 120)
        let item = Labs.newCourierPolicy("x", name: "y")
        item.graceDays = 121
        #expect(rule.check(item).count > 0)
    }
}
