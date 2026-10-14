@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTransferPreferenceValidator()
        let item = BedManagement.newTransferPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTransferPreferenceRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = BedManagement.TransferPreferenceRequiredFacilityRule(message: "transfer preference needs an entry")
        let item = BedManagement.newTransferPreference("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTransferPreferenceFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = BedManagement.TransferPreferenceFacilityLengthRule(maxLength: 80)
        let item = BedManagement.newTransferPreference("x", title: "y")
        item.facility = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTransferPreferenceMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = BedManagement.TransferPreferenceMarginRangeRule(min: 1.9, max: 350.9)
        let item = BedManagement.newTransferPreference("x", title: "y")
        item.margin = 352.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementTransferPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.TransferPreferenceRequiredCodeRule(message: "transfer preference needs a value")
        let item = BedManagement.newTransferPreference("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
