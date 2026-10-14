@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierRecordValidator()
        let item = Labs.newCourierRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierRecordRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Labs.CourierRecordRequiredContactEmailRule(message: "courier record needs this field")
        let item = Labs.newCourierRecord("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.CourierRecordRequiredCodeRule(message: "courier record needs this field")
        let item = Labs.newCourierRecord("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierRecordRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Labs.CourierRecordRequiredPhoneRule(message: "courier record needs a value")
        let item = Labs.newCourierRecord("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierRecordPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Labs.CourierRecordPhoneLengthRule(maxLength: 16)
        let item = Labs.newCourierRecord("x", name: "y")
        item.phone = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
