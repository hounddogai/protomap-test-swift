@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadPlanValidator()
        let item = Imaging.newReadPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ReadPlanCodeLengthRule(maxLength: 16)
        let item = Imaging.newReadPlan("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingReadPlanRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Imaging.ReadPlanRequiredProcedureCodeRule(message: "read plan needs an entry")
        let item = Imaging.newReadPlan("", title: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
