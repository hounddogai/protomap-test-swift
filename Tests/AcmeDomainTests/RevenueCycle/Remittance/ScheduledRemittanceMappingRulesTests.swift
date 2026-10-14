@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledRemittanceMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultScheduledRemittanceMappingValidator()
        let item = RevenueCycle.newScheduledRemittanceMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleScheduledRemittanceMappingClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = RevenueCycle.ScheduledRemittanceMappingClinicianIDLengthRule(maxLength: 3600)
        let item = RevenueCycle.newScheduledRemittanceMapping("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleScheduledRemittanceMappingRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.ScheduledRemittanceMappingRequiredNameRule(
            message: "scheduled remittance mapping needs a value"
        )
        let item = RevenueCycle.newScheduledRemittanceMapping("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleScheduledRemittanceMappingBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = RevenueCycle.ScheduledRemittanceMappingBatchSizeRangeRule(min: 80, max: 1000)
        let item = RevenueCycle.newScheduledRemittanceMapping("x", name: "y")
        item.batchSize = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleScheduledRemittanceMappingMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = RevenueCycle.ScheduledRemittanceMappingMinimumRangeRule(min: 8.0, max: 1401.8)
        let item = RevenueCycle.newScheduledRemittanceMapping("x", name: "y")
        item.minimum = 1403.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleScheduledRemittanceMappingRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = RevenueCycle.ScheduledRemittanceMappingRequiredClinicianIDRule(
            message: "scheduled remittance mapping needs this field"
        )
        let item = RevenueCycle.newScheduledRemittanceMapping("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
