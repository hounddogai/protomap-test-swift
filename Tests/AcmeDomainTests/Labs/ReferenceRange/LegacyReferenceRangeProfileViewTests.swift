@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyReferenceRangeProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newLegacyReferenceRangeProfile("code-626", label: "label-271")
        let view = Labs.toLegacyReferenceRangeProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toLegacyReferenceRangeProfileViews([item, item]).count == 2)
    }
}
