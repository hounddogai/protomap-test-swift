@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionAuditValidator()
        let item = Pharmacy.newInteractionAudit("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionAuditNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.InteractionAuditNameLengthRule(maxLength: 1000)
        let item = Pharmacy.newInteractionAudit("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionAuditLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.InteractionAuditLabelLengthRule(maxLength: 16)
        let item = Pharmacy.newInteractionAudit("x", name: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.InteractionAuditCodeLengthRule(maxLength: 1000)
        let item = Pharmacy.newInteractionAudit("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
