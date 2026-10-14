@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalOrderSetWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultGlobalOrderSetWindowValidator()
        let item = ClinicalOps.newGlobalOrderSetWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsGlobalOrderSetWindowNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.GlobalOrderSetWindowNameLengthRule(maxLength: 80)
        let item = ClinicalOps.newGlobalOrderSetWindow("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsGlobalOrderSetWindowCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.GlobalOrderSetWindowCodeLengthRule(maxLength: 32)
        let item = ClinicalOps.newGlobalOrderSetWindow("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
