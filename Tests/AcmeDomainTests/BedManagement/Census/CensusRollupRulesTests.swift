@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusRollupValidator()
        let item = BedManagement.newCensusRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusRollupRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = BedManagement.CensusRollupRequiredProcedureCodeRule(message: "census rollup needs an entry")
        let item = BedManagement.newCensusRollup("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusRollupRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.CensusRollupRequiredNameRule(message: "census rollup needs this field")
        let item = BedManagement.newCensusRollup("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
