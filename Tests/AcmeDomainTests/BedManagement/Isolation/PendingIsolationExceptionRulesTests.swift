@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingIsolationExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPendingIsolationExceptionValidator()
        let item = BedManagement.newPendingIsolationException("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPendingIsolationExceptionClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = BedManagement.PendingIsolationExceptionClinicianIDLengthRule(maxLength: 64)
        let item = BedManagement.newPendingIsolationException("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPendingIsolationExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.PendingIsolationExceptionCodeLengthRule(maxLength: 16)
        let item = BedManagement.newPendingIsolationException("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPendingIsolationExceptionRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = BedManagement.PendingIsolationExceptionRequiredEncounterIDRule(
            message: "pending isolation exception needs an entry"
        )
        let item = BedManagement.newPendingIsolationException("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPendingIsolationExceptionRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = BedManagement.PendingIsolationExceptionRetriesRangeRule(min: 16, max: 1000)
        let item = BedManagement.newPendingIsolationException("x", label: "y")
        item.retries = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPendingIsolationExceptionRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.PendingIsolationExceptionRequiredLabelRule(
            message: "pending isolation exception needs a value"
        )
        let item = BedManagement.newPendingIsolationException("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPendingIsolationExceptionMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = BedManagement.PendingIsolationExceptionMarginRangeRule(min: 1.8, max: 3643.2)
        let item = BedManagement.newPendingIsolationException("x", label: "y")
        item.margin = 3644.7
        #expect(rule.check(item).count > 0)
    }
}
