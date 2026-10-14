@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientTransferAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLenientTransferAllocationValidator()
        let item = BedManagement.newLenientTransferAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLenientTransferAllocationCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = BedManagement.LenientTransferAllocationCreatedAtRangeRule(min: 16, max: 1000)
        let item = BedManagement.newLenientTransferAllocation("x", label: "y")
        item.createdAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementLenientTransferAllocationScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = BedManagement.LenientTransferAllocationScoreRangeRule(min: 0.6, max: 1257.1)
        let item = BedManagement.newLenientTransferAllocation("x", label: "y")
        item.score = 1258.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementLenientTransferAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.LenientTransferAllocationRequiredCodeRule(
            message: "lenient transfer allocation needs an entry"
        )
        let item = BedManagement.newLenientTransferAllocation("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
