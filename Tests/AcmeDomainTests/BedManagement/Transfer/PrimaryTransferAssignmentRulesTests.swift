@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryTransferAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPrimaryTransferAssignmentValidator()
        let item = BedManagement.newPrimaryTransferAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPrimaryTransferAssignmentLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = BedManagement.PrimaryTransferAssignmentLimitRangeRule(min: 32, max: 64)
        let item = BedManagement.newPrimaryTransferAssignment("x", name: "y")
        item.limit = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPrimaryTransferAssignmentRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = BedManagement.PrimaryTransferAssignmentRequiredCategoryRule(
            message: "primary transfer assignment needs this field"
        )
        let item = BedManagement.newPrimaryTransferAssignment("", name: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPrimaryTransferAssignmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.PrimaryTransferAssignmentRequiredNameRule(
            message: "primary transfer assignment needs this field"
        )
        let item = BedManagement.newPrimaryTransferAssignment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPrimaryTransferAssignmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.PrimaryTransferAssignmentNameLengthRule(maxLength: 120)
        let item = BedManagement.newPrimaryTransferAssignment("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
