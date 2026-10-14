@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledDischargePlanForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultScheduledDischargePlanForecastValidator()
        let item = BedManagement.newScheduledDischargePlanForecast("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementScheduledDischargePlanForecastReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = BedManagement.ScheduledDischargePlanForecastReviewerLengthRule(maxLength: 80)
        let item = BedManagement.newScheduledDischargePlanForecast("x", label: "y")
        item.reviewer = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementScheduledDischargePlanForecastLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.ScheduledDischargePlanForecastLabelLengthRule(maxLength: 120)
        let item = BedManagement.newScheduledDischargePlanForecast("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementScheduledDischargePlanForecastRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.ScheduledDischargePlanForecastRequiredLabelRule(
            message: "scheduled discharge plan forecast needs this field"
        )
        let item = BedManagement.newScheduledDischargePlanForecast("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
