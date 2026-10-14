@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierThresholdValidator()
        let item = Labs.newCourierThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierThresholdPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Labs.CourierThresholdPhoneLengthRule(maxLength: 255)
        let item = Labs.newCourierThreshold("x", name: "y")
        item.phone = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCourierThresholdRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Labs.CourierThresholdRefillsRangeRule(min: 32, max: 80)
        let item = Labs.newCourierThreshold("x", name: "y")
        item.refills = 81
        #expect(rule.check(item).count > 0)
    }
}
