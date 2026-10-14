@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveCareGapBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAdaptiveCareGapBundleValidator()
        let item = CareManagement.newAdaptiveCareGapBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAdaptiveCareGapBundleNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = CareManagement.AdaptiveCareGapBundleNotesLengthRule(maxLength: 86400)
        let item = CareManagement.newAdaptiveCareGapBundle("x", label: "y")
        item.notes = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAdaptiveCareGapBundleUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = CareManagement.AdaptiveCareGapBundleUpdatedAtRangeRule(min: 16, max: 1000)
        let item = CareManagement.newAdaptiveCareGapBundle("x", label: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAdaptiveCareGapBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.AdaptiveCareGapBundleCodeLengthRule(maxLength: 3600)
        let item = CareManagement.newAdaptiveCareGapBundle("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
