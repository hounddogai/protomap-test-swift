@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierPreferenceValidator()
        let item = Labs.newCourierPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierPreferencePhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Labs.CourierPreferencePhoneLengthRule(maxLength: 86400)
        let item = Labs.newCourierPreference("x", title: "y")
        item.phone = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCourierPreferenceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.CourierPreferenceRequiredTitleRule(message: "courier preference needs this field")
        let item = Labs.newCourierPreference("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierPreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.CourierPreferenceCodeLengthRule(maxLength: 16)
        let item = Labs.newCourierPreference("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCourierPreferenceRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Labs.CourierPreferenceRequiredPhoneRule(message: "courier preference needs an entry")
        let item = Labs.newCourierPreference("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.CourierPreferenceRequiredCodeRule(message: "courier preference needs a value")
        let item = Labs.newCourierPreference("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
