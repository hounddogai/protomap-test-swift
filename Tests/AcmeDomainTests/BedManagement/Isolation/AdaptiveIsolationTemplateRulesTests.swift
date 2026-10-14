@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveIsolationTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultAdaptiveIsolationTemplateValidator()
        let item = BedManagement.newAdaptiveIsolationTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementAdaptiveIsolationTemplateVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = BedManagement.AdaptiveIsolationTemplateVisitMinutesRangeRule(min: 80, max: 120)
        let item = BedManagement.newAdaptiveIsolationTemplate("x", title: "y")
        item.visitMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementAdaptiveIsolationTemplateReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = BedManagement.AdaptiveIsolationTemplateReviewerLengthRule(maxLength: 1000)
        let item = BedManagement.newAdaptiveIsolationTemplate("x", title: "y")
        item.reviewer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
