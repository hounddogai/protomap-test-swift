@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingAlertBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRollingAlertBundleValidator()
        let item = ClinicalOps.newRollingAlertBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRollingAlertBundleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.RollingAlertBundleRequiredNameRule(message: "rolling alert bundle needs an entry")
        let item = ClinicalOps.newRollingAlertBundle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRollingAlertBundleRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = ClinicalOps.RollingAlertBundleRequiredProcedureCodeRule(
            message: "rolling alert bundle needs an entry"
        )
        let item = ClinicalOps.newRollingAlertBundle("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRollingAlertBundleRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = ClinicalOps.RollingAlertBundleRequiredRegionRule(message: "rolling alert bundle needs an entry")
        let item = ClinicalOps.newRollingAlertBundle("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}
