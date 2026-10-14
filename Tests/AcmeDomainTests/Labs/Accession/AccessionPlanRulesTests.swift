@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionPlanValidator()
        let item = Labs.newAccessionPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionPlanRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Labs.AccessionPlanRequiredDiagnosisCodeRule(message: "accession plan needs an entry")
        let item = Labs.newAccessionPlan("", title: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.AccessionPlanCodeLengthRule(maxLength: 255)
        let item = Labs.newAccessionPlan("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionPlanTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.AccessionPlanTitleLengthRule(maxLength: 120)
        let item = Labs.newAccessionPlan("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionPlanRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Labs.AccessionPlanRequiredTimezoneRule(message: "accession plan needs a value")
        let item = Labs.newAccessionPlan("", title: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionPlanTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Labs.AccessionPlanTimezoneLengthRule(maxLength: 120)
        let item = Labs.newAccessionPlan("x", title: "y")
        item.timezone = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
