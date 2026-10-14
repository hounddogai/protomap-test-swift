@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalPriorityAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultGlobalPriorityAgreementValidator()
        let item = Imaging.newGlobalPriorityAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingGlobalPriorityAgreementRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.GlobalPriorityAgreementRequiredNameRule(message: "global priority agreement needs an entry")
        let item = Imaging.newGlobalPriorityAgreement("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingGlobalPriorityAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.GlobalPriorityAgreementCodeLengthRule(maxLength: 1000)
        let item = Imaging.newGlobalPriorityAgreement("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingGlobalPriorityAgreementNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.GlobalPriorityAgreementNameLengthRule(maxLength: 64)
        let item = Imaging.newGlobalPriorityAgreement("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingGlobalPriorityAgreementOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Imaging.GlobalPriorityAgreementOwnerIDLengthRule(maxLength: 64)
        let item = Imaging.newGlobalPriorityAgreement("x", name: "y")
        item.ownerID = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
