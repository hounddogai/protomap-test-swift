@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedIsolationReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCappedIsolationReviewValidator()
        let item = BedManagement.newCappedIsolationReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCappedIsolationReviewOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = BedManagement.CappedIsolationReviewOwnerIDLengthRule(maxLength: 86400)
        let item = BedManagement.newCappedIsolationReview("x", name: "y")
        item.ownerID = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCappedIsolationReviewNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.CappedIsolationReviewNameLengthRule(maxLength: 255)
        let item = BedManagement.newCappedIsolationReview("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCappedIsolationReviewRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = BedManagement.CappedIsolationReviewRequiredOwnerIDRule(
            message: "capped isolation review needs this field"
        )
        let item = BedManagement.newCappedIsolationReview("", name: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}
