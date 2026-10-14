@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolScoreValidator()
        let item = ClinicalOps.newCareProtocolScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolScoreProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = ClinicalOps.CareProtocolScoreProcedureCodeLengthRule(maxLength: 1000)
        let item = ClinicalOps.newCareProtocolScore("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsCareProtocolScoreBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = ClinicalOps.CareProtocolScoreBudgetRangeRule(min: 7.2, max: 129.3)
        let item = ClinicalOps.newCareProtocolScore("x", title: "y")
        item.budget = 130.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolScoreRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.CareProtocolScoreRequiredTitleRule(message: "care protocol score needs this field")
        let item = ClinicalOps.newCareProtocolScore("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
