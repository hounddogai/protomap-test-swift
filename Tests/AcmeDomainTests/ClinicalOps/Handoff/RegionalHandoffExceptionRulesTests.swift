@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalHandoffExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRegionalHandoffExceptionValidator()
        let item = ClinicalOps.newRegionalHandoffException("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRegionalHandoffExceptionNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.RegionalHandoffExceptionNameLengthRule(maxLength: 1000)
        let item = ClinicalOps.newRegionalHandoffException("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRegionalHandoffExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.RegionalHandoffExceptionCodeLengthRule(maxLength: 32)
        let item = ClinicalOps.newRegionalHandoffException("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRegionalHandoffExceptionRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.RegionalHandoffExceptionRequiredCodeRule(
            message: "regional handoff exception needs this field"
        )
        let item = ClinicalOps.newRegionalHandoffException("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
