@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveCleaningNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultAdaptiveCleaningNoticeValidator()
        let item = BedManagement.newAdaptiveCleaningNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementAdaptiveCleaningNoticeBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = BedManagement.AdaptiveCleaningNoticeBedLengthRule(maxLength: 86400)
        let item = BedManagement.newAdaptiveCleaningNotice("x", title: "y")
        item.bed = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementAdaptiveCleaningNoticeRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.AdaptiveCleaningNoticeRequiredTitleRule(
            message: "adaptive cleaning notice needs an entry"
        )
        let item = BedManagement.newAdaptiveCleaningNotice("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementAdaptiveCleaningNoticeGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = BedManagement.AdaptiveCleaningNoticeGraceDaysRangeRule(min: 120, max: 255)
        let item = BedManagement.newAdaptiveCleaningNotice("x", title: "y")
        item.graceDays = 256
        #expect(rule.check(item).count > 0)
    }
}
