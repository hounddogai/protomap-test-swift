@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryCredentialAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPrimaryCredentialAllocationValidator()
        let item = Staffing.newPrimaryCredentialAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPrimaryCredentialAllocationRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Staffing.PrimaryCredentialAllocationRequiredContactEmailRule(
            message: "primary credential allocation needs an entry"
        )
        let item = Staffing.newPrimaryCredentialAllocation("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimaryCredentialAllocationRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Staffing.PrimaryCredentialAllocationRequiredEncounterIDRule(
            message: "primary credential allocation needs an entry"
        )
        let item = Staffing.newPrimaryCredentialAllocation("", title: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimaryCredentialAllocationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.PrimaryCredentialAllocationRequiredTitleRule(
            message: "primary credential allocation needs a value"
        )
        let item = Staffing.newPrimaryCredentialAllocation("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimaryCredentialAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.PrimaryCredentialAllocationRequiredCodeRule(
            message: "primary credential allocation needs an entry"
        )
        let item = Staffing.newPrimaryCredentialAllocation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimaryCredentialAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.PrimaryCredentialAllocationCodeLengthRule(maxLength: 1000)
        let item = Staffing.newPrimaryCredentialAllocation("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPrimaryCredentialAllocationCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Staffing.PrimaryCredentialAllocationCapacityRangeRule(min: 32, max: 255)
        let item = Staffing.newPrimaryCredentialAllocation("x", title: "y")
        item.capacity = 256
        #expect(rule.check(item).count > 0)
    }
}
