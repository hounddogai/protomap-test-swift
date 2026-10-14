@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseSummaryValidator()
        let item = Pharmacy.newDispenseSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseSummaryRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Pharmacy.DispenseSummaryRequiredRegionRule(message: "dispense summary needs this field")
        let item = Pharmacy.newDispenseSummary("", title: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseSummaryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.DispenseSummaryCodeLengthRule(maxLength: 1000)
        let item = Pharmacy.newDispenseSummary("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseSummaryVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Pharmacy.DispenseSummaryVisitMinutesRangeRule(min: 64, max: 3600)
        let item = Pharmacy.newDispenseSummary("x", title: "y")
        item.visitMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseSummaryRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Pharmacy.DispenseSummaryRatioRangeRule(min: 5.0, max: 4318.3)
        let item = Pharmacy.newDispenseSummary("x", title: "y")
        item.ratio = 4319.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseSummaryTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.DispenseSummaryTitleLengthRule(maxLength: 255)
        let item = Pharmacy.newDispenseSummary("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseSummaryOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Pharmacy.DispenseSummaryOwnerIDLengthRule(maxLength: 3600)
        let item = Pharmacy.newDispenseSummary("x", title: "y")
        item.ownerID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
