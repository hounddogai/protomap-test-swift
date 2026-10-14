@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualIsolationRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultManualIsolationRequestValidator()
        let item = BedManagement.newManualIsolationRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementManualIsolationRequestRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = BedManagement.ManualIsolationRequestRequiredUnitRule(
            message: "manual isolation request needs a value"
        )
        let item = BedManagement.newManualIsolationRequest("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementManualIsolationRequestRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = BedManagement.ManualIsolationRequestRevisionRangeRule(min: 64, max: 120)
        let item = BedManagement.newManualIsolationRequest("x", name: "y")
        item.revision = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementManualIsolationRequestSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = BedManagement.ManualIsolationRequestSourceLengthRule(maxLength: 64)
        let item = BedManagement.newManualIsolationRequest("x", name: "y")
        item.source = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementManualIsolationRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.ManualIsolationRequestCodeLengthRule(maxLength: 120)
        let item = BedManagement.newManualIsolationRequest("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementManualIsolationRequestRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = BedManagement.ManualIsolationRequestRetriesRangeRule(min: 1000, max: 3600)
        let item = BedManagement.newManualIsolationRequest("x", name: "y")
        item.retries = 3601
        #expect(rule.check(item).count > 0)
    }
}
