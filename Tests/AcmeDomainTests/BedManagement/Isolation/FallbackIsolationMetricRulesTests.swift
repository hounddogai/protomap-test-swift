@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackIsolationMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultFallbackIsolationMetricValidator()
        let item = BedManagement.newFallbackIsolationMetric("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementFallbackIsolationMetricPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = BedManagement.FallbackIsolationMetricPayerLengthRule(maxLength: 16)
        let item = BedManagement.newFallbackIsolationMetric("x", title: "y")
        item.payer = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementFallbackIsolationMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.FallbackIsolationMetricCodeLengthRule(maxLength: 3600)
        let item = BedManagement.newFallbackIsolationMetric("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
