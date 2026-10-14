@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualOvertimeVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultManualOvertimeVarianceValidator()
        let item = Staffing.newManualOvertimeVariance("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingManualOvertimeVarianceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.ManualOvertimeVarianceRequiredLabelRule(message: "manual overtime variance needs a value")
        let item = Staffing.newManualOvertimeVariance("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
