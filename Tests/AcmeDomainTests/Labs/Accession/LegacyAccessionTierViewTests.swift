@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyAccessionTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newLegacyAccessionTier("code-61", label: "label-671")
        let view = Labs.toLegacyAccessionTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toLegacyAccessionTierViews([item, item]).count == 2)
    }
}
