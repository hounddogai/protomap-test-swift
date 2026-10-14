@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingAccessionRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRollingAccessionRecord("code-437", name: "name-406")
        let view = Labs.toRollingAccessionRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRollingAccessionRecordViews([item, item]).count == 2)
    }
}
