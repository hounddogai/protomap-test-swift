@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newReferenceRangeRecord("code-804", name: "name-164")
        let view = Labs.toReferenceRangeRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toReferenceRangeRecordViews([item, item]).count == 2)
    }
}
