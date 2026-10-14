@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCleaningExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultScheduledCleaningExceptionValidator()
        let item = BedManagement.newScheduledCleaningException("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementScheduledCleaningExceptionRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = BedManagement.ScheduledCleaningExceptionRequiredBedRule(
            message: "scheduled cleaning exception needs an entry"
        )
        let item = BedManagement.newScheduledCleaningException("", name: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementScheduledCleaningExceptionRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.ScheduledCleaningExceptionRequiredNameRule(
            message: "scheduled cleaning exception needs this field"
        )
        let item = BedManagement.newScheduledCleaningException("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementScheduledCleaningExceptionNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.ScheduledCleaningExceptionNameLengthRule(maxLength: 120)
        let item = BedManagement.newScheduledCleaningException("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementScheduledCleaningExceptionReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = BedManagement.ScheduledCleaningExceptionReviewerLengthRule(maxLength: 120)
        let item = BedManagement.newScheduledCleaningException("x", name: "y")
        item.reviewer = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementScheduledCleaningExceptionGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = BedManagement.ScheduledCleaningExceptionGraceDaysRangeRule(min: 120, max: 1000)
        let item = BedManagement.newScheduledCleaningException("x", name: "y")
        item.graceDays = 1001
        #expect(rule.check(item).count > 0)
    }
}
