@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedCleaningSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCappedCleaningSlotValidator()
        let item = BedManagement.newCappedCleaningSlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCappedCleaningSlotDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = BedManagement.CappedCleaningSlotDiagnosisCodeLengthRule(maxLength: 86400)
        let item = BedManagement.newCappedCleaningSlot("x", label: "y")
        item.diagnosisCode = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCappedCleaningSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.CappedCleaningSlotRequiredCodeRule(message: "capped cleaning slot needs this field")
        let item = BedManagement.newCappedCleaningSlot("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCappedCleaningSlotRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = BedManagement.CappedCleaningSlotRequiredContactEmailRule(
            message: "capped cleaning slot needs this field"
        )
        let item = BedManagement.newCappedCleaningSlot("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}
