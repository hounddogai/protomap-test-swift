@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedAccessionWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCappedAccessionWindow("code-182", title: "title-127")
        let view = Labs.toCappedAccessionWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCappedAccessionWindowViews([item, item]).count == 2)
    }
}
