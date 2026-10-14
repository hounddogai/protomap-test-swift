@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedReferenceRangeRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCappedReferenceRangeRecord("code-746", title: "title-779")
        let view = Labs.toCappedReferenceRangeRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCappedReferenceRangeRecordViews([item, item]).count == 2)
    }
}
