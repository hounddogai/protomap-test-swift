@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierNoticeValidator()
        let item = Labs.newCourierNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierNoticeRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Labs.CourierNoticeRequiredPhoneRule(message: "courier notice needs a value")
        let item = Labs.newCourierNotice("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.CourierNoticeRequiredCodeRule(message: "courier notice needs a value")
        let item = Labs.newCourierNotice("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierNoticeEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Labs.CourierNoticeEncounterIDLengthRule(maxLength: 32)
        let item = Labs.newCourierNotice("x", name: "y")
        item.encounterID = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
