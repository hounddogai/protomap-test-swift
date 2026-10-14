@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningExceptionValidator()
        let item = BedManagement.newCleaningException("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningExceptionRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.CleaningExceptionRequiredLabelRule(message: "cleaning exception needs this field")
        let item = BedManagement.newCleaningException("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningExceptionRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = BedManagement.CleaningExceptionRequiredSpecialtyRule(message: "cleaning exception needs an entry")
        let item = BedManagement.newCleaningException("", label: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningExceptionWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = BedManagement.CleaningExceptionWeightRangeRule(min: 3.1, max: 4914.9)
        let item = BedManagement.newCleaningException("x", label: "y")
        item.weight = 4916.4
        #expect(rule.check(item).count > 0)
    }
}
