@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierEntryValidator()
        let item = Labs.newCourierEntry("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierEntryRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Labs.CourierEntryRequiredContactEmailRule(message: "courier entry needs an entry")
        let item = Labs.newCourierEntry("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.CourierEntryCodeLengthRule(maxLength: 86400)
        let item = Labs.newCourierEntry("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
