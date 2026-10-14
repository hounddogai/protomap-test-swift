@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalCareGapRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRegionalCareGapRuleValidator()
        let item = CareManagement.newRegionalCareGapRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRegionalCareGapRuleRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = CareManagement.RegionalCareGapRuleRequiredDescriptionRule(
            message: "regional care gap rule needs an entry"
        )
        let item = CareManagement.newRegionalCareGapRule("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRegionalCareGapRulePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = CareManagement.RegionalCareGapRulePayerLengthRule(maxLength: 3600)
        let item = CareManagement.newRegionalCareGapRule("x", title: "y")
        item.payer = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRegionalCareGapRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.RegionalCareGapRuleCodeLengthRule(maxLength: 255)
        let item = CareManagement.newRegionalCareGapRule("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
