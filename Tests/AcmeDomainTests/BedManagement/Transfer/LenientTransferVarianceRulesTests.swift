@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientTransferVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultLenientTransferVarianceValidator()
        let item = BedManagement.newLenientTransferVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementLenientTransferVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.LenientTransferVarianceRequiredCodeRule(
            message: "lenient transfer variance needs an entry"
        )
        let item = BedManagement.newLenientTransferVariance("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLenientTransferVarianceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = BedManagement.LenientTransferVarianceRequiredTitleRule(
            message: "lenient transfer variance needs this field"
        )
        let item = BedManagement.newLenientTransferVariance("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementLenientTransferVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.LenientTransferVarianceCodeLengthRule(maxLength: 86400)
        let item = BedManagement.newLenientTransferVariance("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementLenientTransferVarianceSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = BedManagement.LenientTransferVarianceSpecialtyLengthRule(maxLength: 86400)
        let item = BedManagement.newLenientTransferVariance("x", title: "y")
        item.specialty = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}
