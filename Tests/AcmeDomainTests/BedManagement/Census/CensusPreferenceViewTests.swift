@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCensusPreference("code-556", title: "title-277")
        let view = BedManagement.toCensusPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCensusPreferenceViews([item, item]).count == 2)
    }
}
