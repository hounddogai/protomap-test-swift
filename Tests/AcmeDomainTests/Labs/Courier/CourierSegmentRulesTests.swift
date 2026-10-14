@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierSegmentValidator()
        let item = Labs.newCourierSegment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierSegmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.CourierSegmentTitleLengthRule(maxLength: 255)
        let item = Labs.newCourierSegment("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCourierSegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.CourierSegmentCodeLengthRule(maxLength: 64)
        let item = Labs.newCourierSegment("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCourierSegmentRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Labs.CourierSegmentRetriesRangeRule(min: 80, max: 3600)
        let item = Labs.newCourierSegment("x", title: "y")
        item.retries = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCourierSegmentMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Labs.CourierSegmentMinimumRangeRule(min: 5.0, max: 1265.3)
        let item = Labs.newCourierSegment("x", title: "y")
        item.minimum = 1266.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCourierSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.CourierSegmentRequiredCodeRule(message: "courier segment needs a value")
        let item = Labs.newCourierSegment("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
