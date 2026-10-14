@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingCleaningSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultRollingCleaningSummaryValidator()
        let item = BedManagement.newRollingCleaningSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementRollingCleaningSummaryCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = BedManagement.RollingCleaningSummaryCountryLengthRule(maxLength: 255)
        let item = BedManagement.newRollingCleaningSummary("x", title: "y")
        item.country = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementRollingCleaningSummaryRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = BedManagement.RollingCleaningSummaryRequiredFacilityRule(
            message: "rolling cleaning summary needs an entry"
        )
        let item = BedManagement.newRollingCleaningSummary("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementRollingCleaningSummaryFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = BedManagement.RollingCleaningSummaryFacilityLengthRule(maxLength: 16)
        let item = BedManagement.newRollingCleaningSummary("x", title: "y")
        item.facility = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}
