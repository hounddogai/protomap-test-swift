@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalSubstitutionTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newSeasonalSubstitutionTarget("code-153", label: "label-256")
        let view = Pharmacy.toSeasonalSubstitutionTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toSeasonalSubstitutionTargetViews([item, item]).count == 2)
    }
}
