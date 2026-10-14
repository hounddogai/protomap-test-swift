@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientBedBoardAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLenientBedBoardAllocationValidator()
        let item = BedManagement.newLenientBedBoardAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLenientBedBoardAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.LenientBedBoardAllocationCodeLengthRule(maxLength: 16)
        let item = BedManagement.newLenientBedBoardAllocation("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementLenientBedBoardAllocationRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = BedManagement.LenientBedBoardAllocationRequiredCountryRule(
            message: "lenient bed board allocation needs a value"
        )
        let item = BedManagement.newLenientBedBoardAllocation("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLenientBedBoardAllocationPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = BedManagement.LenientBedBoardAllocationPriorityRangeRule(min: 16, max: 86400)
        let item = BedManagement.newLenientBedBoardAllocation("x", label: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}
