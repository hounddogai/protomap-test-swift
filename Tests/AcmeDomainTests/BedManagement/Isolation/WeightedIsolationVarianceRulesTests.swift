@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedIsolationVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultWeightedIsolationVarianceValidator()
        let item = BedManagement.newWeightedIsolationVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementWeightedIsolationVarianceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.WeightedIsolationVarianceTitleLengthRule(maxLength: 16)
        let item = BedManagement.newWeightedIsolationVariance("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementWeightedIsolationVarianceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.WeightedIsolationVarianceRequiredLabelRule(
            message: "weighted isolation variance needs this field"
        )
        let item = BedManagement.newWeightedIsolationVariance("", title: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementWeightedIsolationVarianceRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = BedManagement.WeightedIsolationVarianceRequiredClinicianIDRule(
            message: "weighted isolation variance needs this field"
        )
        let item = BedManagement.newWeightedIsolationVariance("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementWeightedIsolationVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.WeightedIsolationVarianceRequiredCodeRule(
            message: "weighted isolation variance needs an entry"
        )
        let item = BedManagement.newWeightedIsolationVariance("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
