@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalSubstitutionQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newSeasonalSubstitutionQuota("code-639", title: "title-254")
        let view = Pharmacy.toSeasonalSubstitutionQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toSeasonalSubstitutionQuotaViews([item, item]).count == 2)
    }
}
