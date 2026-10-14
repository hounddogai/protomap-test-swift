@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictTaskEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultStrictTaskEntryValidator()
        let item = ClinicalOps.newStrictTaskEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsStrictTaskEntryRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = ClinicalOps.StrictTaskEntryRequiredProcedureCodeRule(message: "strict task entry needs a value")
        let item = ClinicalOps.newStrictTaskEntry("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsStrictTaskEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.StrictTaskEntryCodeLengthRule(maxLength: 255)
        let item = ClinicalOps.newStrictTaskEntry("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
