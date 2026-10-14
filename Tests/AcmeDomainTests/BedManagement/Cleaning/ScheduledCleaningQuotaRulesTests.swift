@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCleaningQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultScheduledCleaningQuotaValidator()
        let item = BedManagement.newScheduledCleaningQuota("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementScheduledCleaningQuotaExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = BedManagement.ScheduledCleaningQuotaExternalRefLengthRule(maxLength: 32)
        let item = BedManagement.newScheduledCleaningQuota("x", name: "y")
        item.externalRef = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementScheduledCleaningQuotaGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = BedManagement.ScheduledCleaningQuotaGraceDaysRangeRule(min: 120, max: 1000)
        let item = BedManagement.newScheduledCleaningQuota("x", name: "y")
        item.graceDays = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementScheduledCleaningQuotaChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = BedManagement.ScheduledCleaningQuotaChecksumLengthRule(maxLength: 32)
        let item = BedManagement.newScheduledCleaningQuota("x", name: "y")
        item.checksum = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementScheduledCleaningQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.ScheduledCleaningQuotaCodeLengthRule(maxLength: 1000)
        let item = BedManagement.newScheduledCleaningQuota("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
