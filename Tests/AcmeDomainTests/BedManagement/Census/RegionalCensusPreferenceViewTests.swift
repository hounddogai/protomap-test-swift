@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalCensusPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newRegionalCensusPreference("code-499", title: "title-743")
        let view = BedManagement.toRegionalCensusPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toRegionalCensusPreferenceViews([item, item]).count == 2)
    }
}
