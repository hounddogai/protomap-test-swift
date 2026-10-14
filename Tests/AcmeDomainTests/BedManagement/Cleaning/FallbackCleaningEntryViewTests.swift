@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCleaningEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newFallbackCleaningEntry("code-730", name: "name-47")
        let view = BedManagement.toFallbackCleaningEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toFallbackCleaningEntryViews([item, item]).count == 2)
    }
}
