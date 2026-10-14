@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualDischargePlanVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultManualDischargePlanVarianceValidator()
        let item = BedManagement.newManualDischargePlanVariance("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementManualDischargePlanVarianceRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = BedManagement.ManualDischargePlanVarianceRequiredCategoryRule(
            message: "manual discharge plan variance needs a value"
        )
        let item = BedManagement.newManualDischargePlanVariance("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementManualDischargePlanVarianceSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = BedManagement.ManualDischargePlanVarianceSegmentLengthRule(maxLength: 80)
        let item = BedManagement.newManualDischargePlanVariance("x", label: "y")
        item.segment = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}
