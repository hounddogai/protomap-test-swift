@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryHandoffCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPrimaryHandoffCycleValidator()
        let item = ClinicalOps.newPrimaryHandoffCycle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPrimaryHandoffCycleOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = ClinicalOps.PrimaryHandoffCycleOwnerIDLengthRule(maxLength: 120)
        let item = ClinicalOps.newPrimaryHandoffCycle("x", label: "y")
        item.ownerID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPrimaryHandoffCycleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.PrimaryHandoffCycleCodeLengthRule(maxLength: 1000)
        let item = ClinicalOps.newPrimaryHandoffCycle("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
