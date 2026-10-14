@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedSpecimenTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCappedSpecimenTier("code-394", name: "name-744")
        let view = Labs.toCappedSpecimenTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCappedSpecimenTierViews([item, item]).count == 2)
    }
}
