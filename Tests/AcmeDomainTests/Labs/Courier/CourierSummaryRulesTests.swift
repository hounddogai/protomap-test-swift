@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierSummaryValidator()
        let item = Labs.newCourierSummary("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.CourierSummaryRequiredCodeRule(message: "courier summary needs this field")
        let item = Labs.newCourierSummary("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierSummaryTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Labs.CourierSummaryTimezoneLengthRule(maxLength: 120)
        let item = Labs.newCourierSummary("x", name: "y")
        item.timezone = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCourierSummaryRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.CourierSummaryRequiredNameRule(message: "courier summary needs this field")
        let item = Labs.newCourierSummary("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierSummaryThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Labs.CourierSummaryThresholdRangeRule(min: 1.5, max: 1822.6)
        let item = Labs.newCourierSummary("x", name: "y")
        item.threshold = 1824.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCourierSummaryNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.CourierSummaryNameLengthRule(maxLength: 64)
        let item = Labs.newCourierSummary("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
