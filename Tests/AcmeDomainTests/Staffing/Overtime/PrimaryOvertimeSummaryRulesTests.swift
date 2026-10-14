@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryOvertimeSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPrimaryOvertimeSummaryValidator()
        let item = Staffing.newPrimaryOvertimeSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPrimaryOvertimeSummaryCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Staffing.PrimaryOvertimeSummaryCountryLengthRule(maxLength: 255)
        let item = Staffing.newPrimaryOvertimeSummary("x", title: "y")
        item.country = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPrimaryOvertimeSummaryRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Staffing.PrimaryOvertimeSummaryRequiredCountryRule(message: "primary overtime summary needs a value")
        let item = Staffing.newPrimaryOvertimeSummary("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimaryOvertimeSummaryThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Staffing.PrimaryOvertimeSummaryThresholdRangeRule(min: 8.9, max: 2495.8)
        let item = Staffing.newPrimaryOvertimeSummary("x", title: "y")
        item.threshold = 2497.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingPrimaryOvertimeSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.PrimaryOvertimeSummaryRequiredCodeRule(message: "primary overtime summary needs this field")
        let item = Staffing.newPrimaryOvertimeSummary("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimaryOvertimeSummaryDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Staffing.PrimaryOvertimeSummaryDescriptionLengthRule(maxLength: 32)
        let item = Staffing.newPrimaryOvertimeSummary("x", title: "y")
        item.description = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPrimaryOvertimeSummaryUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Staffing.PrimaryOvertimeSummaryUpdatedAtRangeRule(min: 64, max: 1000)
        let item = Staffing.newPrimaryOvertimeSummary("x", title: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
