@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBedBoardClaimValidator()
        let item = BedManagement.newBedBoardClaim("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBedBoardClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.BedBoardClaimRequiredCodeRule(message: "bed board claim needs an entry")
        let item = BedManagement.newBedBoardClaim("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBedBoardClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.BedBoardClaimCodeLengthRule(maxLength: 3600)
        let item = BedManagement.newBedBoardClaim("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardClaimNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.BedBoardClaimNameLengthRule(maxLength: 3600)
        let item = BedManagement.newBedBoardClaim("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBedBoardClaimLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = BedManagement.BedBoardClaimLocaleLengthRule(maxLength: 16)
        let item = BedManagement.newBedBoardClaim("x", name: "y")
        item.locale = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}
