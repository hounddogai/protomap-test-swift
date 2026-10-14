@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangeProfile("code-172", name: "name-88")
        let view = Labs.toReferenceRangeProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangeProfileViews([item, item]).count == 2)
    }
}
