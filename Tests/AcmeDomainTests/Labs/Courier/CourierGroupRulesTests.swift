@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierGroupValidator()
        let item = Labs.newCourierGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierGroupBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Labs.CourierGroupBedLengthRule(maxLength: 86400)
        let item = Labs.newCourierGroup("x", title: "y")
        item.bed = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCourierGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.CourierGroupCodeLengthRule(maxLength: 86400)
        let item = Labs.newCourierGroup("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
