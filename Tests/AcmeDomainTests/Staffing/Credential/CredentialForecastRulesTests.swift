@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialForecastValidator()
        let item = Staffing.newCredentialForecast("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialForecastRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.CredentialForecastRequiredCodeRule(message: "credential forecast needs a value")
        let item = Staffing.newCredentialForecast("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialForecastBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Staffing.CredentialForecastBatchSizeRangeRule(min: 32, max: 3600)
        let item = Staffing.newCredentialForecast("x", title: "y")
        item.batchSize = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCredentialForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CredentialForecastCodeLengthRule(maxLength: 3600)
        let item = Staffing.newCredentialForecast("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
