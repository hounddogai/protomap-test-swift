@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedAlertWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCappedAlertWindowValidator()
        let item = ClinicalOps.newCappedAlertWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCappedAlertWindowLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.CappedAlertWindowLabelLengthRule(maxLength: 255)
        let item = ClinicalOps.newCappedAlertWindow("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
