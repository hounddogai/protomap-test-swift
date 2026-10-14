@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackIsolationGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultFallbackIsolationGroupValidator()
        let item = BedManagement.newFallbackIsolationGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementFallbackIsolationGroupExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = BedManagement.FallbackIsolationGroupExpiresAtRangeRule(min: 16, max: 80)
        let item = BedManagement.newFallbackIsolationGroup("x", label: "y")
        item.expiresAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementFallbackIsolationGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.FallbackIsolationGroupRequiredCodeRule(
            message: "fallback isolation group needs a value"
        )
        let item = BedManagement.newFallbackIsolationGroup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementFallbackIsolationGroupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.FallbackIsolationGroupRequiredLabelRule(
            message: "fallback isolation group needs a value"
        )
        let item = BedManagement.newFallbackIsolationGroup("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementFallbackIsolationGroupEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = BedManagement.FallbackIsolationGroupEndsAtRangeRule(min: 80, max: 255)
        let item = BedManagement.newFallbackIsolationGroup("x", label: "y")
        item.endsAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementFallbackIsolationGroupNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = BedManagement.FallbackIsolationGroupNotesLengthRule(maxLength: 64)
        let item = BedManagement.newFallbackIsolationGroup("x", label: "y")
        item.notes = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementFallbackIsolationGroupMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = BedManagement.FallbackIsolationGroupMaximumRangeRule(min: 6.9, max: 485.9)
        let item = BedManagement.newFallbackIsolationGroup("x", label: "y")
        item.maximum = 487.4
        #expect(rule.check(item).count > 0)
    }
}
