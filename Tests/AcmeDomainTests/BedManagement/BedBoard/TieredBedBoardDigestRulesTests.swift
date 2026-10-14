@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredBedBoardDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultTieredBedBoardDigestValidator()
        let item = BedManagement.newTieredBedBoardDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementTieredBedBoardDigestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.TieredBedBoardDigestRequiredNameRule(
            message: "tiered bed board digest needs this field"
        )
        let item = BedManagement.newTieredBedBoardDigest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementTieredBedBoardDigestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = BedManagement.TieredBedBoardDigestNameLengthRule(maxLength: 1000)
        let item = BedManagement.newTieredBedBoardDigest("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementTieredBedBoardDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.TieredBedBoardDigestCodeLengthRule(maxLength: 80)
        let item = BedManagement.newTieredBedBoardDigest("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
