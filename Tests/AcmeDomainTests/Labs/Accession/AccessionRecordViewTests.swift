@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newAccessionRecord("code-433", name: "name-70")
        let view = Labs.toAccessionRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toAccessionRecordViews([item, item]).count == 2)
    }
}
