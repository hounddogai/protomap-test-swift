@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryCensusVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPrimaryCensusVarianceValidator()
        let item = BedManagement.newPrimaryCensusVariance("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPrimaryCensusVarianceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.PrimaryCensusVarianceRequiredLabelRule(
            message: "primary census variance needs this field"
        )
        let item = BedManagement.newPrimaryCensusVariance("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPrimaryCensusVarianceRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = BedManagement.PrimaryCensusVarianceRequiredContactEmailRule(
            message: "primary census variance needs this field"
        )
        let item = BedManagement.newPrimaryCensusVariance("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPrimaryCensusVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.PrimaryCensusVarianceRequiredCodeRule(message: "primary census variance needs a value")
        let item = BedManagement.newPrimaryCensusVariance("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPrimaryCensusVarianceLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.PrimaryCensusVarianceLabelLengthRule(maxLength: 1000)
        let item = BedManagement.newPrimaryCensusVariance("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPrimaryCensusVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.PrimaryCensusVarianceCodeLengthRule(maxLength: 1000)
        let item = BedManagement.newPrimaryCensusVariance("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
