@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedReferenceRangeRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newBatchedReferenceRangeRecord("code-576", title: "title-512")
        let view = Labs.toBatchedReferenceRangeRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toBatchedReferenceRangeRecordViews([item, item]).count == 2)
    }
}
