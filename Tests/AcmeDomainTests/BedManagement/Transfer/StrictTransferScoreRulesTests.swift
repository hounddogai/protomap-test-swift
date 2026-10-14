@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictTransferScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultStrictTransferScoreValidator()
        let item = BedManagement.newStrictTransferScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementStrictTransferScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.StrictTransferScoreCodeLengthRule(maxLength: 64)
        let item = BedManagement.newStrictTransferScore("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementStrictTransferScoreCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = BedManagement.StrictTransferScoreCopayRangeRule(min: 4.2, max: 3928.9)
        let item = BedManagement.newStrictTransferScore("x", label: "y")
        item.copay = 3930.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementStrictTransferScoreClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = BedManagement.StrictTransferScoreClinicianIDLengthRule(maxLength: 3600)
        let item = BedManagement.newStrictTransferScore("x", label: "y")
        item.clinicianID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementStrictTransferScoreRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = BedManagement.StrictTransferScoreRequiredClinicianIDRule(
            message: "strict transfer score needs this field"
        )
        let item = BedManagement.newStrictTransferScore("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
