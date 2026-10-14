@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPanelSchedule("code-920", label: "label-996")
        let view = Labs.toPanelScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPanelScheduleViews([item, item]).count == 2)
    }
}
