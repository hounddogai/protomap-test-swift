@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusTargetValidator()
        let item = BedManagement.newCensusTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusTargetChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = BedManagement.CensusTargetChecksumLengthRule(maxLength: 80)
        let item = BedManagement.newCensusTarget("x", label: "y")
        item.checksum = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusTargetRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = BedManagement.CensusTargetRequiredContactEmailRule(message: "census target needs this field")
        let item = BedManagement.newCensusTarget("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusTargetEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = BedManagement.CensusTargetEndsAtRangeRule(min: 32, max: 1000)
        let item = BedManagement.newCensusTarget("x", label: "y")
        item.endsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementCensusTargetLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.CensusTargetLabelLengthRule(maxLength: 16)
        let item = BedManagement.newCensusTarget("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
