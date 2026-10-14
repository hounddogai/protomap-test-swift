@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledSpecimenTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newScheduledSpecimenTier("code-958", title: "title-534")
        let view = Labs.toScheduledSpecimenTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toScheduledSpecimenTierViews([item, item]).count == 2)
    }
}
