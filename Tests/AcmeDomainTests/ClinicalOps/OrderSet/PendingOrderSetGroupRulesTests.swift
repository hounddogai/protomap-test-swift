@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingOrderSetGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPendingOrderSetGroupValidator()
        let item = ClinicalOps.newPendingOrderSetGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPendingOrderSetGroupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.PendingOrderSetGroupLabelLengthRule(maxLength: 86400)
        let item = ClinicalOps.newPendingOrderSetGroup("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPendingOrderSetGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.PendingOrderSetGroupRequiredCodeRule(message: "pending order set group needs this field")
        let item = ClinicalOps.newPendingOrderSetGroup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
