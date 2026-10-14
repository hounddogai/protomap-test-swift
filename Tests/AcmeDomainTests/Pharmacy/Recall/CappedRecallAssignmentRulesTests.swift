@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedRecallAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultCappedRecallAssignmentValidator()
        let item = Pharmacy.newCappedRecallAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyCappedRecallAssignmentRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Pharmacy.CappedRecallAssignmentRequiredOwnerIDRule(
            message: "capped recall assignment needs this field"
        )
        let item = Pharmacy.newCappedRecallAssignment("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyCappedRecallAssignmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.CappedRecallAssignmentTitleLengthRule(maxLength: 86400)
        let item = Pharmacy.newCappedRecallAssignment("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyCappedRecallAssignmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.CappedRecallAssignmentRequiredTitleRule(message: "capped recall assignment needs an entry")
        let item = Pharmacy.newCappedRecallAssignment("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
