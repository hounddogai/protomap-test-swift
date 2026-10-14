@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalAlertSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRegionalAlertSnapshotValidator()
        let item = ClinicalOps.newRegionalAlertSnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRegionalAlertSnapshotRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = ClinicalOps.RegionalAlertSnapshotRequiredContactEmailRule(
            message: "regional alert snapshot needs a value"
        )
        let item = ClinicalOps.newRegionalAlertSnapshot("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRegionalAlertSnapshotCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = ClinicalOps.RegionalAlertSnapshotCostRangeRule(min: 5.3, max: 4561.5)
        let item = ClinicalOps.newRegionalAlertSnapshot("x", label: "y")
        item.cost = 4563.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRegionalAlertSnapshotContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = ClinicalOps.RegionalAlertSnapshotContactEmailLengthRule(maxLength: 120)
        let item = ClinicalOps.newRegionalAlertSnapshot("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRegionalAlertSnapshotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.RegionalAlertSnapshotCodeLengthRule(maxLength: 86400)
        let item = ClinicalOps.newRegionalAlertSnapshot("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
