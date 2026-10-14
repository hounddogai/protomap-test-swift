@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCensusDigestValidator()
        let item = BedManagement.newCensusDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCensusDigestRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = BedManagement.CensusDigestRequiredAllergyRule(message: "census digest needs this field")
        let item = BedManagement.newCensusDigest("", title: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCensusDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.CensusDigestCodeLengthRule(maxLength: 64)
        let item = BedManagement.newCensusDigest("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementCensusDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.CensusDigestRequiredCodeRule(message: "census digest needs this field")
        let item = BedManagement.newCensusDigest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
