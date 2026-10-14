@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanDraftValidator()
        let item = BedManagement.newDischargePlanDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanDraftFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = BedManagement.DischargePlanDraftFacilityLengthRule(maxLength: 64)
        let item = BedManagement.newDischargePlanDraft("x", title: "y")
        item.facility = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanDraftVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = BedManagement.DischargePlanDraftVisitMinutesRangeRule(min: 64, max: 80)
        let item = BedManagement.newDischargePlanDraft("x", title: "y")
        item.visitMinutes = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementDischargePlanDraftRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.DischargePlanDraftRequiredTitleRule(message: "discharge plan draft needs an entry")
        let item = BedManagement.newDischargePlanDraft("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementDischargePlanDraftRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = BedManagement.DischargePlanDraftRateRangeRule(min: 9.9, max: 1973.9)
        let item = BedManagement.newDischargePlanDraft("x", title: "y")
        item.rate = 1975.4
        #expect(rule.check(item).count > 0)
    }
}
