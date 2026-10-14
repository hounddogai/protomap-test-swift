@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingCleaningEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newRollingCleaningEntry("code-748", label: "label-216")
        let view = BedManagement.toRollingCleaningEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toRollingCleaningEntryViews([item, item]).count == 2)
    }
}
