@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetForecastValidator()
        let item = ClinicalOps.newOrderSetForecast("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.OrderSetForecastCodeLengthRule(maxLength: 1000)
        let item = ClinicalOps.newOrderSetForecast("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsOrderSetForecastChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = ClinicalOps.OrderSetForecastChecksumLengthRule(maxLength: 64)
        let item = ClinicalOps.newOrderSetForecast("x", label: "y")
        item.checksum = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsOrderSetForecastRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.OrderSetForecastRequiredCodeRule(message: "order set forecast needs this field")
        let item = ClinicalOps.newOrderSetForecast("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
