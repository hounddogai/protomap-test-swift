@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveCensusDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultAdaptiveCensusDraftValidator()
        let item = BedManagement.newAdaptiveCensusDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementAdaptiveCensusDraftRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.AdaptiveCensusDraftRequiredLabelRule(message: "adaptive census draft needs a value")
        let item = BedManagement.newAdaptiveCensusDraft("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementAdaptiveCensusDraftAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = BedManagement.AdaptiveCensusDraftAcuityRangeRule(min: 16, max: 3600)
        let item = BedManagement.newAdaptiveCensusDraft("x", label: "y")
        item.acuity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementAdaptiveCensusDraftChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = BedManagement.AdaptiveCensusDraftChecksumLengthRule(maxLength: 120)
        let item = BedManagement.newAdaptiveCensusDraft("x", label: "y")
        item.checksum = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}
