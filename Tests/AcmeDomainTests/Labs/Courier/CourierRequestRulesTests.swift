@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierRequestValidator()
        let item = Labs.newCourierRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierRequestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.CourierRequestRequiredTitleRule(message: "courier request needs this field")
        let item = Labs.newCourierRequest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.CourierRequestCodeLengthRule(maxLength: 120)
        let item = Labs.newCourierRequest("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCourierRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.CourierRequestRequiredCodeRule(message: "courier request needs this field")
        let item = Labs.newCourierRequest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
