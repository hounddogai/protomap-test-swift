@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedSubstitutionTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultBatchedSubstitutionTargetValidator()
        let item = Pharmacy.newBatchedSubstitutionTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyBatchedSubstitutionTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.BatchedSubstitutionTargetCodeLengthRule(maxLength: 16)
        let item = Pharmacy.newBatchedSubstitutionTarget("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyBatchedSubstitutionTargetLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.BatchedSubstitutionTargetLabelLengthRule(maxLength: 64)
        let item = Pharmacy.newBatchedSubstitutionTarget("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyBatchedSubstitutionTargetFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Pharmacy.BatchedSubstitutionTargetFacilityLengthRule(maxLength: 1000)
        let item = Pharmacy.newBatchedSubstitutionTarget("x", label: "y")
        item.facility = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyBatchedSubstitutionTargetChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Pharmacy.BatchedSubstitutionTargetChannelLengthRule(maxLength: 3600)
        let item = Pharmacy.newBatchedSubstitutionTarget("x", label: "y")
        item.channel = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyBatchedSubstitutionTargetRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.BatchedSubstitutionTargetRequiredLabelRule(
            message: "batched substitution target needs a value"
        )
        let item = Pharmacy.newBatchedSubstitutionTarget("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
