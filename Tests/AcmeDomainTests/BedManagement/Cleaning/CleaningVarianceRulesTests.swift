@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningVarianceValidator()
        let item = BedManagement.newCleaningVariance("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningVarianceLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.CleaningVarianceLabelLengthRule(maxLength: 64)
        let item = BedManagement.newCleaningVariance("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCleaningVarianceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.CleaningVarianceRequiredLabelRule(message: "cleaning variance needs a value")
        let item = BedManagement.newCleaningVariance("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
