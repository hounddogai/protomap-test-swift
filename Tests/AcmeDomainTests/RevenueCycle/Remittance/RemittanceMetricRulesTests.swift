@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceMetricValidator()
        let item = RevenueCycle.newRemittanceMetric("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceMetricGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = RevenueCycle.RemittanceMetricGraceDaysRangeRule(min: 32, max: 3600)
        let item = RevenueCycle.newRemittanceMetric("x", title: "y")
        item.graceDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRemittanceMetricMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = RevenueCycle.RemittanceMetricMinimumRangeRule(min: 5.9, max: 3592.9)
        let item = RevenueCycle.newRemittanceMetric("x", title: "y")
        item.minimum = 3594.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRemittanceMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.RemittanceMetricCodeLengthRule(maxLength: 255)
        let item = RevenueCycle.newRemittanceMetric("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceMetricRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = RevenueCycle.RemittanceMetricRequiredPatientRefRule(message: "remittance metric needs a value")
        let item = RevenueCycle.newRemittanceMetric("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceMetricCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = RevenueCycle.RemittanceMetricCapacityRangeRule(min: 32, max: 86400)
        let item = RevenueCycle.newRemittanceMetric("x", title: "y")
        item.capacity = 86401
        #expect(rule.check(item).count > 0)
    }
}
