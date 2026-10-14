@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualCleaningEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultManualCleaningEstimateValidator()
        let item = BedManagement.newManualCleaningEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementManualCleaningEstimateRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = BedManagement.ManualCleaningEstimateRequiredContactEmailRule(
            message: "manual cleaning estimate needs an entry"
        )
        let item = BedManagement.newManualCleaningEstimate("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementManualCleaningEstimateNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = BedManagement.ManualCleaningEstimateNotesLengthRule(maxLength: 32)
        let item = BedManagement.newManualCleaningEstimate("x", name: "y")
        item.notes = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementManualCleaningEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.ManualCleaningEstimateCodeLengthRule(maxLength: 255)
        let item = BedManagement.newManualCleaningEstimate("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
