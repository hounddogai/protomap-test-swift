@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangeWindow("code-34", title: "title-617")
        let view = Labs.toReferenceRangeWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangeWindowViews([item, item]).count == 2)
    }
}
