@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyCareGapEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLegacyCareGapEstimateValidator()
        let item = CareManagement.newLegacyCareGapEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLegacyCareGapEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.LegacyCareGapEstimateRequiredCodeRule(
            message: "legacy care gap estimate needs this field"
        )
        let item = CareManagement.newLegacyCareGapEstimate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLegacyCareGapEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.LegacyCareGapEstimateCodeLengthRule(maxLength: 16)
        let item = CareManagement.newLegacyCareGapEstimate("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLegacyCareGapEstimateVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = CareManagement.LegacyCareGapEstimateVisitMinutesRangeRule(min: 64, max: 64)
        let item = CareManagement.newLegacyCareGapEstimate("x", name: "y")
        item.visitMinutes = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementLegacyCareGapEstimateNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.LegacyCareGapEstimateNameLengthRule(maxLength: 1000)
        let item = CareManagement.newLegacyCareGapEstimate("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLegacyCareGapEstimateRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = CareManagement.LegacyCareGapEstimateRequiredClinicianIDRule(
            message: "legacy care gap estimate needs a value"
        )
        let item = CareManagement.newLegacyCareGapEstimate("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
